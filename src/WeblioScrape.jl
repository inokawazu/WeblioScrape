module WeblioScrape

export getexamples, searchexamples

using Gumbo, Cascadia, HTTP

using URIs: escapeuri

"`makewebliourl(q)` constructs the weblio url to search at."
makewebliourl(q) = "https://ejje.weblio.jp/sentence/content/" * escapeuri(q) * "/"

"`getexamples(url::String, pg=1)` goes out to Weblio to get the examples from the url \
at a give page."
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

"`getmaxpages(url)` gets the max page of search results."
function getmaxpages(url)
    html = HTTP.get(url)
    parsed = parsehtml(String(html))
    page = eachmatch(sel".pgntionWrp", parsed.root)

    isempty(page) && return 1

    pagenumbers = eachmatch(sel"a", page[1])

    parse(Int, string(pagenumbers[end-1][1]))
end

"`getallpages(url, pglimit::Integer = typemax(Int))` gets all the examples from several \
up to an the pglimit or the max pages given."
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

"`searchexamples(q::String, pglimit::Integer = typemax(Int))` returns the Japnese-English \
examples for search q (which must be in Japanese) up to the pglimit or the max search pages \
returned."
function searchexamples(q::String, pglimit::Integer = typemax(Int))
    @show url = makewebliourl(q)
    getallpages(url, pglimit)
end

getcjj(q) = eachmatch(sel".qotCJJ",q)[1]
getcje(q) = eachmatch(sel".qotCJE",q)[1]

"`extractex(q)` removes html fluff around example text."
function extractex(q)
    try 
        return join(map(extractex, q.children), " ")
    catch e
        println(e)
        @warn "No children, returning nothing"
        return ""
    end
end

"`extractex(t::Gumbo.HTMLText)` converts HTMLText to text."
extractex(t::Gumbo.HTMLText) =  string(t)

"`extractex(_::Gumbo.HTMLElement{:span})` returns an emtpy result because spans contain \
extraneous information."
extractex(_::Gumbo.HTMLElement{:span}) = "" 

"`cleanspaces(x)` cleans up excess spaces in `x`"
cleanspaces(x) =  replace(x, r"\s{2,}"=>" ") |> strip
"`deletespaces(x)` deletes all space characters in `x`"
deletespaces(x) =  replace(x, r"\s"=>"")


#TEMP
export TEST_URL, testpage, testall
TEST_URL = "https://ejje.weblio.jp/sentence/content/%E3%81%8A%E9%A1%98%E3%81%84/"

testpage() = getexamples(TEST_URL)
testall() = getallpages(TEST_URL)
#TEMP

end # module
