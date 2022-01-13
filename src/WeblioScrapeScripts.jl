module WeblioScrape

export TEST_URL, getexamples, searchexamples, testpage, testall

using Gumbo, Cascadia, HTTP

using URIs: escapeuri

TEST_URL = "https://ejje.weblio.jp/sentence/content/%E3%81%8A%E9%A1%98%E3%81%84/"

makewebliourl(q) = "https://ejje.weblio.jp/sentence/content/" * escapeuri(q) * "/"

function getexamples(url::String, pg=1)
    html = HTTP.get(url*string(pg))

    if html.status != 200 
        @warn "GET request failed with $(html.status). Returing an empty example set."
        return Matrix{String}()
    end

    parsed = parsehtml(String(html))
    qs = eachmatch(sel".qotC",parsed.root)

    jpexs = map(deletespaces∘extractex∘getcjj, qs)
    enexs = map(cleanspaces∘extractex∘getcje, qs)
    return hcat(jpexs, enexs)
end

function getmaxpages(url)
    html = HTTP.get(url)
    parsed = parsehtml(String(html))
    page = eachmatch(sel".pgntionWrp", parsed.root)

    isempty(page) && return 1

    pagenumbers = eachmatch(sel"a", page[1])

    parse(Int, string(pagenumbers[end-1][1]))
end

function getallpages(url, pglimit::Integer = typemax(Int))

    maxpgs = min(getmaxpages(url), pglimit)
    pg = 1
    examples = Array{String}(undef, 0, 2)
    while pg <= maxpgs
        found = getexamples(url,pg)
        @info "Found $(size(found)[1]) examples from page $pg"
        examples = vcat(examples, found)
        pg+=1
    end
    return examples

end

function searchexamples(q::String, pglimit::Integer = typemax(Int))
    @show url = makewebliourl(q)
    getallpages(url, pglimit)
end

getcjj(q) = eachmatch(sel".qotCJJ",q)[1]
getcje(q) = eachmatch(sel".qotCJE",q)[1]

function extractex(q)
    try 
        return join(map(extractex, q.children), " ")
    catch e
        println(e)
        @warn "No children, returning nothing"
        return ""
    end
end

extractex(t::Gumbo.HTMLText) =  string(t)
extractex(_::Gumbo.HTMLElement{:span}) = "" 

cleanspaces(x) =  replace(x, r"\s{2,}"=>" ") |> strip
deletespaces(x) =  replace(x, r"\s"=>"")


#TEMP
testpage() = getexamples(TEST_URL)
testall() = getallpages(TEST_URL)
#TEMP

end # module
