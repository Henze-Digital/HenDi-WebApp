xquery version "3.1" encoding "UTF-8";

module namespace app="http://xquery.weber-gesamtausgabe.de/modules/app";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace gndo="https://d-nb.info/standards/elementset/gnd#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace gn="http://www.geonames.org/ontology#";
declare namespace sr="http://www.w3.org/2005/sparql-results#";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
declare namespace ft="http://exist-db.org/xquery/lucene";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";

import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace crud="http://xquery.weber-gesamtausgabe.de/modules/crud" at "crud.xqm";
import module namespace img="http://xquery.weber-gesamtausgabe.de/modules/img" at "img.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace controller="http://xquery.weber-gesamtausgabe.de/modules/controller" at "controller.xqm";
import module namespace bibl="http://xquery.weber-gesamtausgabe.de/modules/bibl" at "bibl.xqm";
import module namespace search="http://xquery.weber-gesamtausgabe.de/modules/search" at "search.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "wdt.xqm";
import module namespace gl="http://xquery.weber-gesamtausgabe.de/modules/gl" at "gl.xqm";
import module namespace er="http://xquery.weber-gesamtausgabe.de/modules/external-requests" at "external-requests.xqm";
import module namespace functx="http://www.functx.com";
import module namespace kwic="http://exist-db.org/xquery/kwic";
import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";
import module namespace app-shared="http://xquery.weber-gesamtausgabe.de/modules/app-shared" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/app-shared.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/date.xqm";
import module namespace wega-util-shared="http://xquery.weber-gesamtausgabe.de/modules/wega-util-shared" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/wega-util-shared.xqm";
import module namespace hwh-util="http://henze-digital.zenmem.de/modules/hwh-util" at "hwh-util.xqm";

(:
 : ****************************
 : Generic functions
 : ****************************
:)

(:~
 : Creates an xhtml:a link to a WeGA document
 :
 : @author Peter Stadler
 : @param $doc the document to create the link for
 : @param $content the string content for the xhtml a element
 : @param $lang the language switch (en, de)
 : @param $attributes a sequence of attribute-value-pairs, e.g. ('class=xy', 'style=display:block')
 :)
declare function app:createDocLink($doc as document-node()?, $content as xs:string, $lang as xs:string, $attributes as xs:string*) as element(xhtml:a) {
    let $href := controller:create-url-for-doc($doc, $lang)
    let $docID :=  $doc/root()/*/@xml:id
    return 
    element xhtml:a {
        attribute href {$href},
        if(exists($attributes)) then for $att in $attributes return attribute {substring-before($att, '=')} {substring-after($att, '=')} 
        else (),
        $content
    }
};

(:~
 : Creates an xhtml:a link to a WeGA document with popover preview
 : This is a shortcut version of the 3-arity function app:createDocLink()
 :
 : @author Peter Stadler
 : @param $doc the document to create the link for
 : @param $content the string content for the xhtml a element
 : @param $lang the language switch (en, de)
 : @param $attributes a sequence of attribute-value-pairs, e.g. ('class=xy', 'style=display:block')
 : @param $popover whether to add class attributes for popovers
 : @return a html:a element
 :)
declare function app:createDocLink($doc as document-node()?, $content as xs:string, $lang as xs:string, $attributes as xs:string*, $popover as xs:boolean) as element(xhtml:a) {
    if($popover) then 
        let $docID := $doc/*/data(@xml:id)
        let $docType := config:get-doctype-by-id($docID)
        return app:createDocLink($doc,$content, $lang, ($attributes, string-join(('class=preview', $docType, $docID), ' ')))
    else app:createDocLink($doc,$content, $lang, $attributes)
};

declare 
    %templates:wrap
    function app:documentFooter($node as node(), $model as map(*)) as map(*) {
        let $lang := $model('lang')
        let $dataProps := config:get-data-props($model('docID'))
        let $author := map:get($dataProps, 'author')
        let $date := xs:dateTime(map:get($dataProps, 'dateTime'))
        let $formatedDate := 
            try { date:format-date($date, $config:default-date-picture-string($lang), $lang) }
            catch * { wega-util:log-to-file('warn', 'Failed to get data history properties for ' || $model('docID') ) }
        let $version := config:expath-descriptor()/@version => string()
        let $versionDate := date:format-date(xs:date(config:get-option('versionDate')), $config:default-date-picture-string($lang), $lang)
        return
            map {
                'bugEmail' : config:get-option('bugEmail'),
                'permalink' : config:permalink($model('docID')),
                'versionNews' : app:createDocLink(crud:doc(config:get-option('versionNews')), lang:get-language-string('versionInformation',($version, $versionDate), $lang), $lang, ()),
                'latestChange' :
                    if($config:isDevelopment) then lang:get-language-string('lastChangeDateWithAuthor',($formatedDate,$author),$lang)
                    else lang:get-language-string('lastChangeDateWithoutAuthor', $formatedDate, $lang)
            }
};

declare 
    %templates:wrap
    function app:bugreport($node as node(), $model as map(*)) as map(*) {
    	map {
                'bugEmail' : config:get-option('bugEmail')
            }
};

declare 
    %templates:default("format", "WeGA")
    function app:download-link($node as node(), $model as map(*), $format as xs:string) as element() {
        let $url := replace(controller:create-url-for-doc($model('doc'), $model('lang')), '\.html', '.xml')
        return 
            element {node-name($node)} {
                $node/@* except $node/@href,
                attribute href {
                    switch($format)
                    case 'WeGA' return $url
                    case 'tei_all' return $url || '?format=tei_all'
                    case 'mei_all' return $url || '?format=mei_all'
                    case 'tei_simplePrint' return $url || '?format=tei_simplePrint'
                    case 'text' return replace($url, '\.xml', '.txt')
                    case 'dta' return $url || '?format=dta'
                    default return wega-util:log-to-file('warn', 'app:download-link(): unsupported format "' || $format || '"!')
                },
                templates:process($node/node(), $model)
            }
};

(:~
 : get and set line-wrap variable
 : (whether a user prefers code examples with or without wrapped lines)
 :)
declare function app:set-line-wrap($node as node(), $model as map(*)) as element() {
    element {node-name($node)} {
        if(wega-util-shared:semantic-boolean($model?settings?('line-wrap'))) then ( 
            $node/@* except $node/@class,
            attribute class {string-join(($node/@class, 'line-wrap'), ' ')}
        )
        else $node/@*,
        templates:process($node/node(), $model)
    }
};



(:
 : ****************************
 : Breadcrumbs 
 : ****************************
:)
declare
    %templates:default("lang", "en")
    function app:breadcrumb-person($node as node(), $model as map(*), $lang as xs:string) as map(*)? {
        let $file := crud:doc(substring-before($model?('exist:resource'),'.html'))
        let $fileAuthors := (if($file/tei:biblStruct//tei:author[@key])then($file/tei:biblStruct//tei:author[@key])else($file/tei:biblStruct//tei:editor[@key]), $file//tei:fileDesc/tei:titleStmt/tei:author[@key], $file//mei:work[1]//mei:persName[@role='cmp' or ancestor::mei:composer][@codedval])
        let $authorElems := for $author in $fileAuthors 
						        let $authorID := $author/(@key|@codedval)
						        let $anonymusID := config:get-option('anonymusID')
						        let $authorElem :=
						            (: NB: there might be multiple anonymous authors :)
						            if ($authorID = $anonymusID) then (query:get-author-element($model?doc)[(count(@key | @codedval) = 0) or ((@key, @codedval) = $anonymusID)])[1]
						            (: NB: there might be multiple occurences of the same person as e.g. composer and lyricist :)
						            else (query:get-author-element($model?doc)[(@key, @codedval) = $authorID])[1]
						        let $href :=
						            if ($authorID = $anonymusID) then ()
						            else controller:create-url-for-doc(crud:doc($authorID), $lang)
						        let $elem := 
						            if($href) then QName('http://www.w3.org/1999/xhtml', 'a')
						            else QName('http://www.w3.org/1999/xhtml', 'span')
						        let $name := wega-util:print-forename-surname-from-nameLike-element($author)
						        return 
						            element {$elem} {
						                $node/@*[not(local-name(.) eq 'href')],
						                if($href) then attribute href {$href} else (),
						                $name
						            }
        where exists($authorElems)
        let $breadcrumb := element {'span'} {
                                    		let $names2Show := 3
                                    		let $authorElemsN := count($authorElems)
                                    		let $names := for $each at $n in $authorElems
                                                    		  where $n lt ($names2Show + 1)
                                                    		  return
                                                    		      ($each , if($n = $names2Show or $n = $authorElemsN) then() else(' / '))
                                    		let $etAl := if($authorElemsN gt $names2Show) then(' / et al.') else()
                                    		return
                                    		($names, $etAl)
                                        }
        
        return
            map {
                'breadcrumb-person' : $breadcrumb
                }
};

declare
    %templates:default("lang", "en")
    function app:breadcrumb-docType($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:a) {
        let $href := config:link-to-current-app(functx:substring-before-last($model('exist:path'), '/'))
        let $display-name := replace(xmldb:decode(functx:substring-after-last($href, '/')), '_', ' ')
        let $elem := 
            if($href and not(contains($href, config:get-option('anonymusID')))) then QName('http://www.w3.org/1999/xhtml', 'a')
            else QName('http://www.w3.org/1999/xhtml', 'span')
        return
            element {$elem} {
                $node/@*[not(local-name(.) eq 'href')],
                if(local-name-from-QName($elem) = 'a') then attribute href {$href} else (),
                $display-name
            }
};

declare 
    %templates:default("lang", "en")
    function app:breadcrumb-register1($node as node(), $model as map(*), $lang as xs:string) as item() {
        switch($model('docType')) 
        case 'indices' return 
            element xhtml:span {
                lang:get-language-string('indices', $lang)
            }
        case 'biblio' case 'news' return 
            element {node-name($node)} {
                $node/@*[not(local-name(.) eq 'href')],
                lang:get-language-string('project', $lang)
            }
        default return
            element {node-name($node)} {
                $node/@*[not(local-name(.) eq 'href')],
                attribute href {config:link-to-current-app(controller:path-to-register('indices', $lang))},
                lang:get-language-string('indices', $lang)
            }
};

declare 
    %templates:default("lang", "en")
    function app:breadcrumb-register2($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:a)? {
        if($model('docType') = 'indices') then ()
        else if ($model('docType') = 'corresp')
        then (
            element {node-name($node)} {
                $node/@*[not(local-name(.) eq 'href')],
                attribute href {config:link-to-current-app(controller:path-to-register('corresp', $lang))},
                lang:get-language-string($model('docType'), $lang)
            }
            )
        else 
            element {node-name($node)} {
                $node/@*,
                lang:get-language-string($model('docType'), $lang)
            }
};

declare 
    %templates:default("lang", "en")
    function app:breadcrumb-var($node as node(), $model as map(*), $lang as xs:string) as element() {
        let $pathTokens := tokenize($model?('exist:path'), '/')
        return 
            element {node-name($node)} {
                $node/@*,
                $pathTokens[3]
            }
};

declare
    %templates:default("lang", "en")
    function app:breadcrumb-var2($node as node(), $model as map(*), $lang as xs:string) as element() {
        let $docID := $model('docID')
        let $breadcrumb := $controller:projectNav[?docID=$docID]?title
        return
            element {node-name($node)} {
                $node/@*,
                lang:get-language-string($breadcrumb,$lang)
            }
};

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:status($node as node(), $model as map(*), $lang as xs:string) as xs:string? {
        let $docStatus := $model('doc')/*/@status | $model('doc')//tei:revisionDesc/@status 
        return
            if($docStatus and $config:options-file/id('environment') eq 'development')
            then lang:get-language-string($docStatus, $lang)
            else ()
};


(:
 : ****************************
 : Navigation / Tabs 
 : ****************************
:)

declare
    %templates:default("lang", "en")
    function app:person-main-tab($node as node(), $model as map(*), $lang as xs:string) as element()? {
        let $tabTitle := normalize-space($node)
        let $count := count($model($tabTitle))
        let $alwaysShowNoCount := $tabTitle = ('biographies', 'history', 'descriptions', 'general')
        return
            if($count gt 0 or $alwaysShowNoCount) then
                element {node-name($node)} {
                        $node/@*[not(name(.)='data-target')],
                        if($node/@data-target) then attribute data-target {replace($node/@data-target, '\$docID', $model('docID'))} else (),
                        lang:get-language-string($tabTitle, $lang),
                        if($alwaysShowNoCount) then () else <small>{' (' || $count || ')'}</small>
                    }
            else 
                element {node-name($node)} {
                    attribute class {'deactivated'}
                }
};

declare
    %templates:default("lang", "en")
    function app:ajax-tab($node as node(), $model as map(*), $lang as xs:string) as element() {
        let $ajax-resource :=
            switch(normalize-space($node))
            case 'XML-Preview' return 'xml.html'
            case 'examples' return if(gl:schemaIdent2docType($model?schemaID) = (for $func in $wdt:functions return $func(())('name'))) then 'examples.html' else ()
            case 'wikipedia-article' return 
                if(count(($model?doc//tei:idno | $model?doc//mei:altId) => er:wikipedia-article-url($lang)) gt 0) then 'wikipedia.html'
                else ()
            case 'adb-article' return if($model?gnd and er:lookup-gnd-from-beaconProvider('adbBeacon', $model?gnd)) then 'adb.html' else ()
            case 'ndb-article' return if($model?gnd and er:lookup-gnd-from-beaconProvider('ndbBeacon', $model?gnd)) then 'ndb.html' else ()
            case 'gnd-entry' return if($model('gnd')) then 'dnb.html' else ()
            case 'backlinks' return if($model('backlinks')) then 'backlinks.html' else ()
            case 'gnd-beacon' return if($model('gnd')) then 'beacon.html' else ()
            default return ()
        let $ajax-url :=
        	if(config:get-doctype-by-id($model('docID')) and $ajax-resource) then config:link-to-current-app(controller:path-to-resource($model('doc'), $lang)[1] || '/' || $ajax-resource)
        	else if(gl:spec($model?specID, $model?schemaID) and $ajax-resource) then config:link-to-current-app(replace($model('exist:path'), '\.[xhtml]+$', '') || '/' || $ajax-resource)
        	else ()
        return
            if($ajax-url) then 
                element {node-name($node)} {
                    $node/@*,
                    attribute data-tab-url {$ajax-url},
                    lang:get-language-string(normalize-space($node), $lang)
                }
            else
                element {node-name($node)} {
                    attribute class {'nav-link deactivated'}
                }
};


declare
    %templates:default("lang", "en")
    function app:facsimile-tab($node as node(), $model as map(*), $lang as xs:string) as element() {
        if(count($model?IIIFImagesMap) gt 0) then 
            element {node-name($node)} {
                $node/@*,
                lang:get-language-string(normalize-space($node), $lang)
            }
        else
            element {node-name($node)} {
                attribute class {'deactivated'}
            }
};

declare
    %templates:default("lang", "en")
    function app:translation-tab($node as node(), $model as map(*), $lang as xs:string) as element()* {
        let $trlDocs := collection(config:get-option('dataCollectionPath'))//tei:relation[@name='isTranslationOf'][@key=$model?docID]/root()
        for $trlDoc at $z in $trlDocs
            let $trlDocLang := $trlDoc//tei:profileDesc/tei:langUsage/tei:language/@ident => string()
            let $trlDocLang := switch ($trlDocLang)
                                case 'en' return 'gb'
                                default return $trlDocLang
            return
                element {node-name($node)} {
		        attribute class {'nav-item gradient-light'},
                    element {'a'} {
                        attribute class {'nav-link'},
                        attribute href {'#translation-' || $z},
                        attribute data-toggle {'tab'},
                        attribute id {'translation-tab-' || $z},
                        lang:get-language-string('translation', $lang),
                        '&#160;',
                        element span {
                            attribute class {'fi fi-' || $trlDocLang}
                        }
                    }
                }
};

declare
    %templates:default("lang", "en")
    function app:enclosure-tab($node as node(), $model as map(*), $lang as xs:string) as element()* {
        let $enclosures := collection(config:get-option('dataCollectionPath'))//tei:relation[@name='isEnclosureOf'][@key=$model?docID]/root()
	    for $enclosure at $z in $enclosures
		    return
		        element {node-name($node)} {
		        attribute class {'nav-item gradient-light'},
                    element {'a'} {
                       attribute class {'nav-link'},
                       attribute href {'#enclosure-' || $z},
                       attribute data-toggle {'tab'},
                       attribute id {'enclosure-tab-' || $z},
                       lang:get-language-string('enclosure', $lang),
                       if(count($enclosures) > 1) then(' (' || $z || ')') else()
                    }
                }
};

declare
    %templates:default("lang", "en")
    function app:envelope-tab($node as node(), $model as map(*), $lang as xs:string) as element()? {
        let $envelopes := collection(config:get-option('dataCollectionPath'))//tei:relation[@name='isEnvelopeOf'][@key=$model?docID]/root()
	    for $envelope at $z in $envelopes
		    return
		        element {node-name($node)} {
                    attribute class {'nav-item gradient-light'},
                    element {'a'} {
                       attribute class {'nav-link'},
                       attribute href {'#envelope-' || $z},
                       attribute data-toggle {'tab'},
                       attribute id {'envelope-tab-' || $z},
                       lang:get-language-string('envelope', $lang),
                       if($z > 1) then(' (' || $z || ')') else()
                    }
                }
};

declare
    %templates:default("lang", "en")
    function app:tab($node as node(), $model as map(*), $lang as xs:string) as element() {
        (: Currently only needed for "PND Beacon Links" :)
        if($model('gnd')) then
            element {node-name($node)} {
                $node/@*,
                normalize-space($node)
            }
        else
            element {node-name($node)} {
                attribute class {'deactivated'}
            }
};

declare
    %templates:wrap
    %templates:default("page", "1")
    %templates:default("lang", "en")
    function app:pagination($node as node(), $model as map(*), $page as xs:string, $lang as xs:string) as element(xhtml:li)* {
        let $page := if($page castable as xs:int) then xs:int($page) else 1
        let $a-element := function($page as xs:int, $text as xs:string) {
            element xhtml:a {
                attribute class {'page-link'},
                (: for AJAX pages (e.g. correspondence) called from a person page we need the data-url attribute :) 
                if($model('docID') = 'indices') then attribute href {app:page-link($model, map { 'page': $page} )}
                (: for index pages there is no javascript needed but a direct refresh of the page :)
                else attribute data-url {app:page-link($model, map { 'page': $page} )},
                $text
            }
        }
        let $last-page := ceiling(count($model('search-results')) div config:entries-per-page()) 
        return
        (
            if($page le 1) then
             <li xmlns="http://www.w3.org/1999/xhtml" class="page-item disabled"><a class="page-link">{'&#x00AB; ' || lang:get-language-string('paginationPrevious', $lang)}</a></li>
             else <li xmlns="http://www.w3.org/1999/xhtml" class="page-item">{$a-element($page - 1, '&#x00AB; ' || lang:get-language-string('paginationPrevious', $lang)) }</li>,
            if($page gt 3) then <li xmlns="http://www.w3.org/1999/xhtml" class="page-item d-none d-sm-inline">{$a-element(1, '1')}</li> else (),
            if($page gt 4) then <li xmlns="http://www.w3.org/1999/xhtml" class="page-item disabled d-none d-sm-inline"><a class="page-link">…</a></li> else (),
            ($page - 2, $page - 1)[. gt 0] ! <li xmlns="http://www.w3.org/1999/xhtml" class="page-item d-none d-lg-inline">{$a-element(., string(.))}</li>,
            <li xmlns="http://www.w3.org/1999/xhtml" class="page-item active"><a class="page-link">{$page}</a></li>,
            ($page + 1, $page + 2)[. le $last-page] ! <li xmlns="http://www.w3.org/1999/xhtml" class="page-item d-none d-lg-inline">{$a-element(., string(.))}</li>,
            if($page + 3 lt $last-page) then <li xmlns="http://www.w3.org/1999/xhtml" class="page-item disabled d-none d-sm-inline"><a class="page-link">…</a></li> else (),
            if($page + 2 lt $last-page) then <li xmlns="http://www.w3.org/1999/xhtml" class="page-item d-none d-sm-inline">{$a-element($last-page, string($last-page))}</li> else (),
            if($page ge $last-page) then
                <li xmlns="http://www.w3.org/1999/xhtml" class="page-item disabled">{
                    <a class="page-link">{lang:get-language-string('paginationNext', $lang) || ' &#x00BB;'}</a>
                }</li>
            else <li xmlns="http://www.w3.org/1999/xhtml" class="page-item">{$a-element($page + 1, lang:get-language-string('paginationNext', $lang) || ' &#x00BB;')}</li>
        )
};

declare
    %templates:wrap
    function app:set-entries-per-page($node as node(), $model as map(*)) as map(*) {
		map {
			'limit' : config:entries-per-page(),
			'moreresults' : if ( count($model('search-results')) gt config:entries-per-page() ) then 'true' else ()
		}
};

declare function app:switch-limit($node as node(), $model as map(*)) as element() {
	element {node-name($node)} {
		if($model?limit = number($node)) then attribute class {'page-item active'} else attribute class {'page-item'},
		element xhtml:a {
			attribute class {'page-link'},
			(: for AJAX pages (e.g. correspondence) called from a person page we need the data-url attribute :) 
            if($model('docID') = 'indices') then attribute href {app:page-link($model, map { 'limit': string($node) } )}
            (: for index pages there is no javascript needed but a direct refresh of the page :)
            else attribute data-url {app:page-link($model, map { 'limit': string($node) } )},
			string($node)
		}
	}
};

(:~
 : construct a link to the current page consisting of URL parameters only
 : helper function for pagination
 :
 : @param $model the current model map with filters etc.
 : @param $params the new parameters that will override (eventually existing parameters from $model)
 : @return a string starting with "?"
~:)
declare %private function app:page-link($model as map(*), $params as map(*)) as xs:string {
	let $URLparams := request:get-parameter-names()[.=($search:valid-params, 'd', 'q', 'oldFromDate', 'oldToDate')]
    let $paramsMap := map:merge((map { 'limit': config:entries-per-page() }, $model('filters'), $URLparams ! map:entry(., request:get-parameter(., ())), $params))
    return
        replace(
	        string-join(
	            map:keys($paramsMap) ! (
	                '&amp;' || string(.) || '=' || string-join(
	                    ($paramsMap(.) ! encode-for-uri(.)),
	                    '&amp;' || string(.) || '=')
	                ), 
	            ''),
            '^&amp;', '?'
        )
};

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:active-nav($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        let $active := $node//xhtml:a/@href[controller:encode-path-segments-for-uri(controller:resolve-link(functx:substring-before-if-contains(., '#'), $model)) = request:get-uri()]
        return
            map {'active-nav': $active}
};

declare 
    %templates:default("lang", "en")
    function app:set-active-nav($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:li) {
        let $active := exists($node//xhtml:a[@href = $model('active-nav')])
        return
            element {node-name($node)} {
                if($active) then (
                    $node/@*[not(name(.)='class')],
                    attribute class {string-join(($node/@class, 'active'), ' ')}
                )
                else $node/@*,
                templates:process($node/node(), $model)
            }
};

declare 
    %templates:default("lang", "en")
    function app:set-active-lang($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:li) {
        let $curLang := lower-case(normalize-space($node))
        let $isActive := $lang = $curLang
        return
            element {node-name($node)} {
                if($isActive) then (
                    $node/@*[not(name(.)='class')],
                    attribute class {string-join(($node/@class, 'active'), ' ')}
                )
                else $node/@*,
                
                (: Child element a takes the link :)
                element xhtml:a {
                    attribute class {"nav-link"},
                    attribute href {
                        if($isActive) then '#'
                        else controller:translate-URI(request:get-uri(), $lang, lower-case(normalize-space($node)))
                    },
                    attribute hreflang { $curLang },
                    attribute lang { $curLang },
                    normalize-space($node)
                }
            }
};

(:~
 : set the maximum dates for the IonRangeSlider
~:)
declare 
    %templates:default("fromDate", "")
    %templates:default("toDate", "")
    function app:set-slider-range($node as node(), $model as map(*), $fromDate as xs:string, $toDate as xs:string) as element(xhtml:input) {
    element {node-name($node)} {
         $node/@*,
         attribute data-min-slider {if($model('oldFromDate') castable as xs:date) then $model('oldFromDate') else $model('earliestDate')},
         attribute data-max-slider {if($model('oldToDate') castable as xs:date) then $model('oldToDate') else $model('latestDate')},
         attribute data-from-slider {if($fromDate castable as xs:date) then $fromDate else $model('earliestDate')},
         attribute data-to-slider {if($toDate castable as xs:date) then $toDate else $model('latestDate')}
    }
};

declare function app:set-facet-checkbox($node as node(), $model as map(*), $key as xs:string) as element(xhtml:input) {
    element {node-name($node)} {
         $node/@*,
         if(map:contains($model('filters'), $key)) then attribute checked {'checked'}
         else ()
    }
};

(:
 : ****************************
 : Popover
 : ****************************
:)
(:~
 : Wrapper for dispatching various document types (in analogy to search:dispatch-preview())
 : Simply redirects to the right fragment from 'templates/includes'
 : Used by templates/ajax/popover.html
 :
 :)
declare function app:popover($node as node(), $model as map(*)) as map(*)* {
    map {
        'result-page-entry' : $model('doc')
    }
};

(:
 : ****************************
 : Index page
 : ****************************
:)

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:word-of-the-day($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        let $words := core:getOrCreateColl('letters', 'A001000A', true())//tei:seg[@type='wordOfTheDay']
        let $random :=
            if(count($words) gt 1) then util:random(count($words) - 1) + 1 (: util:random may return 0 and takes as argument positiveInteger! :)
            else if(count($words) eq 1) then 1
            else wega-util:log-to-file('info', 'app:word-of-the-day(): no words of the day found')
        return 
            map {
                'wordOfTheDay' : 
                    if($random) then str:enquote(str:normalize-space(string-join(str:txtFromTEI($words[$random], $lang), '')), $lang)
                    else str:normalize-space($node/xhtml:h1),
                'wordOfTheDayURL' : 
                    if($random) then controller:create-url-for-doc(crud:doc($words[$random]/ancestor::tei:TEI/string(@xml:id)), $lang)
                    else '#'
            }
};

declare 
    %templates:wrap
    %templates:default("otd-date", "")
    function app:lookup-todays-events($node as node(), $model as map(*), $otd-date as xs:string) as map(*) {
    let $date := 
        if($otd-date castable as xs:date) then xs:date($otd-date)
        else current-date()
    let $events := 
        for $i in query:getTodaysEvents($date)
        order by $i/xs:date(@when) ascending
        return $i
    let $length := count($events)
    return
        map {
            'otd-date' : $date,
            'events1' : subsequence($events, 1, ceiling($length div 2)),
            'events2' : subsequence($events, ceiling($length div 2) + 1)
        }
};

declare function app:print-event($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:span)* {
    let $date := $model?otd-date
    let $teiDate := $model('event')
    let $isJubilee := (year-from-date($date) - $teiDate/year-from-date(@when)) mod 25 = 0
    let $typeOfEvent := 
        if($teiDate/ancestor::tei:correspDesc) then 'letter'
        else if($teiDate[@type='baptism']) then 'isBaptised'
        else if($teiDate/parent::tei:birth) then 'isBorn'
        else if($teiDate[@type='funeral']) then 'wasBuried'
        else if($teiDate/parent::tei:death) then 'dies'
        else ()
    return (
        element xhtml:span {
            if($isJubilee) then (
                attribute class {'jubilee event-year'},
                attribute title {lang:get-language-string('roundYearsAgo',xs:string(year-from-date($date) - $teiDate/year-from-date(@when)), $lang)},
                attribute data-toggle {'tooltip'},
                attribute data-container {'body'}
            )
            else attribute class {'event-year'},
            date:formatYear($teiDate/year-from-date(@when) cast as xs:int, $lang)
        },
        element xhtml:span {
        	attribute class {'event-text'},
            if($typeOfEvent eq 'letter') then app:createLetterLink($teiDate, $lang)
            (:else (wega:createPersonLink($teiDate/root()/*/string(@xml:id), $lang, 'fs'), ' ', lang:get-language-string($typeOfEvent, $lang)):)
            else (app:createDocLink($teiDate/root(), wega-util:print-forename-surname-from-nameLike-element($teiDate/ancestor::tei:person/tei:persName[@type='reg']), $lang, ('class=persons')), ' ', lang:get-language-string($typeOfEvent, $lang))
        }
    )
};

declare function app:print-events-title($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:h2) {
    <xhtml:h2>{lang:get-language-string('whatHappenedOn', format-date($model?otd-date, if($lang eq 'de') then '[D]. [MNn]' else '[MNn] [D]',  $lang, (), ()), $lang)}</xhtml:h2>
};

(:~
 : Helper function for app:print-event
 :
 : @author Peter Stadler
 :)
declare %private function app:createLetterLink($teiDate as element(tei:date)?, $lang as xs:string) as item()* {
    let $sender := app:printCorrespondentName(($teiDate/parent::tei:correspAction[@type='sent']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name])[1], $lang, 'fs')
    let $addressee := app:printCorrespondentName(($teiDate/ancestor::tei:correspDesc/tei:correspAction[@type='received']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name])[1], $lang, 'fs')
    return (
        $sender, ' ', lang:get-language-string('writesTo', $lang), ' ', $addressee, 
        if(ends-with($addressee, '.')) then ' ' else '. ', 
        app:createDocLink($teiDate/root(), concat('[', lang:get-language-string('readOnLetter', $lang), ']'), $lang, ('class=readOn'))
    )
};

(:~
 : Construct a name from a tei:persName, tei:orgName, or tei:name element wrapped in a <span> 
 : If a @key is given on the element the regularized form will be returned, otherwise the content of the element.
 : If the element is empty than "unknown" is returned.
 : 
 : @author Peter Stadler
 : @param $persName the tei:persName, tei:orgName, or tei:name element
 : @param $lang the current language (de|en)
 : @param $order (sf|fs|s) whether to print "surname, forename", or "forename surname", or just the surname
 : @return a html:span element with the constructed name
 :)
declare function app:printCorrespondentName($persName as element()?, $lang as xs:string, $order as xs:string) as element(xhtml:span) {
    if(exists($persName/@key)) then 
        if ($order eq 'fs') then app:createDocLink(crud:doc($persName/string(@key)), wega-util:print-forename-surname-from-nameLike-element($persName), $lang, ('class=' || config:get-doctype-by-id($persName/@key)))
        else if ($order eq 's') then app:createDocLink(crud:doc($persName/string(@key)), functx:substring-before-if-contains(query:title($persName/@key), ', '), $lang, ('class=preview ' || concat($persName/@key, " ", config:get-doctype-by-id($persName/@key))))
        else app:createDocLink(crud:doc($persName/string(@key)), query:title($persName/@key), $lang, ('class=' || config:get-doctype-by-id($persName/@key)))
    else if(not(functx:all-whitespace($persName))) then 
        if ($order eq 'fs') then <xhtml:span class="noDataFound">{wega-util:print-forename-surname-from-nameLike-element($persName)}</xhtml:span>
        else <xhtml:span class="noDataFound">{string($persName)}</xhtml:span>
    else <xhtml:span class="noDataFound">{lang:get-language-string('unknown', $lang)}</xhtml:span>
};

declare 
    %templates:wrap
    function app:index-news-items($node as node(), $model as map(*)) as map(*) {
        map {
            'news' : subsequence(core:getOrCreateColl('news', 'indices', true()), 1, xs:int(config:get-option('maxNews')))
        }
};

declare 
    %templates:default("lang", "en")
    function app:index-news-item($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        map {
            'title' : wdt:news($model?newsItem)?title('html'),
            'date' : date:printDate($model?newsItem//tei:date[parent::tei:publicationStmt], $lang, lang:get-language-string#3, $config:default-date-picture-string),
            'url' : controller:create-url-for-doc($model?newsItem, $lang)
        }
};

declare 
    %templates:default("lang", "en")
    function app:search-options($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:option)* {
        <option xmlns="http://www.w3.org/1999/xhtml" value="all">{lang:get-language-string('all', $lang)}</option>,
        for $docType in $search:wega-docTypes
        let $displayTitle := lang:get-language-string($docType, $lang)
        order by $displayTitle
        return
            element {node-name($node)} {
                attribute value {$docType},
                $displayTitle
            }
};


(:
 : ****************************
 : Place pages
 : ****************************
:)

declare function app:place-details($node as node(), $model as map(*)) as map(*) {
    let $basic-data := app:place-basic-data($node, $model)
    let $gnd := query:get-gnd($model('doc'))
    let $gn-doc := er:grabExternalResource('geonames', $basic-data?geonames-id, ())
    return
        map:merge((
            map {
            'gnd' : $gnd,
            'names' : $model?doc//tei:placeName[@type],
            'backlinks' : core:getOrCreateColl('backlinks', $model('docID'), true()),
            'xml-download-url' : replace(controller:create-url-for-doc($model('doc'), $model('lang')), '\.html', '.xml'),
            'note' : exists($model?doc/tei:place/tei:note),
                'geonames_alternateNames' : 
                for $alternateName in $gn-doc//gn:alternateName 
                group by $name := $alternateName/text()
                order by $name 
                return
                    ($name || ' (' || $alternateName/data(@xml:lang) => string-join(', ') || ')'),
            'geonames_parentCountry' : $gn-doc//gn:parentCountry/analyze-string(@rdf:resource, '/(\d+)/')//fn:group/text() ! query:get-geonames-name(.)
        },
            $basic-data
        ))
};

(:
 : Some additional data that is used in the preview and in the single view
 :)
declare 
    %templates:wrap
    function app:place-basic-data($node as node(), $model as map(*)) as map(*) {
        let $isAssociatedWith := for $association in $model('doc')//(tei:relation[@name="association"]|tei:settlement|tei:country|tei:region|tei:district|tei:bloc)
                                    return
                                        <li><a href="/{$association/@key}.html" xmlns="http://www.w3.org/1999/xhtml">{crud:doc($association/@key)//tei:placeName[@type='reg']}</a></li>
        let $isAssociatedBy := for $association in crud:data-collection('places')[.//(tei:relation[@name="association"]|tei:settlement|tei:country|tei:region|tei:district|tei:bloc)[@key=$model('docID')]]
                                  let $id := $association//tei:place/@xml:id
                                  let $placeName := crud:doc($id)//tei:placeName[@type='reg']
                                  return
                                  <li><a href="/{$id}.html" xmlns="http://www.w3.org/1999/xhtml">{$placeName}</a></li>
        return
            map {
                'geonames-id' : str:normalize-space(($model?doc//tei:idno[@type='geonames'])[1]),
                'coordinates' : str:normalize-space($model?doc//tei:geo),
                'residences': $model('doc')//tei:label[.='Ort'][parent::tei:state]/following-sibling::tei:desc/tei:* ! str:normalize-space(.),
                'geonamesFeatureCode': $model('doc')//tei:label[.='Kategorie'][parent::tei:state]/following-sibling::tei:desc ! str:normalize-space(.),
                'isAssociatedWith': $isAssociatedWith,
                'isAssociatedBy': $isAssociatedBy
            }
};

declare 
    %templates:default("provider", "osm")
    function app:place-link($node as node(), $model as map(*), $provider as xs:string) as element(xhtml:a) {
        let $latLon := tokenize($model?coordinates, '\s+')
        return
            element xhtml:a {
                attribute href {
                    switch($provider)
                    case 'osm' return 'https://www.openstreetmap.org/?mlat=' || $latLon[1] || '&amp;mlon=' || $latLon[2] || '&amp;zoom=11'
                    case 'google' return 'https://www.google.com/maps/@?api=1&amp;map_action=map&amp;zoom=12&amp;basemap=terrain&amp;center=' || string-join($latLon, ',')
                    case 'geoNames' return 'http://geonames.org/' || $model?geonames-id
                    default return ''
                },
                switch($provider)
                case 'osm' return 'OpenStreetMap'
                case 'google' return 'Google'
                case 'geoNames' return $model?geonames-id
                default return ''
            }
};

(:
 : ****************************
 : Work pages
 : ****************************
:)

declare 
    %templates:wrap
    function app:work-basic-data($node as node(), $model as map(*)) as map(*) {
        let $print-titles := function($doc as document-node(), $alt as xs:boolean) {
            for $title in ($doc//mei:meiHead/mei:workList/mei:work[1]/mei:title/mei:titlePart[. != ''][not(@type=('sub','desc'))][exists(@type='alt') = $alt] |
                           $doc//tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[not(@level='s')][exists(@type='alt') = $alt])
            let $titleLang := $title/@xml:lang => string() 
            let $subTitle := if($titleLang)
                             then(($title/following-sibling::mei:titlePart[@type='sub'][string(@xml:lang) = $titleLang])[1])
                             else(($title/following-sibling::mei:titlePart[@type='sub'])[1])
            return <span xmlns="http://www.w3.org/1999/xhtml">{
                string-join((
                    wega-util:transform($title, doc(concat($config:xsl-collection-path, '/works.xsl')), config:get-xsl-params(())),
                    wega-util:transform($subTitle, doc(concat($config:xsl-collection-path, '/works.xsl')), config:get-xsl-params(()))
                    ),
                    '. '
                ),
                if($titleLang) then ' (' || $titleLang || ')'
                else ()
            }</span>
        }
        let $print-titles-desc := function($doc as document-node()) {
            for $titleDesc in $doc//mei:meiHead//mei:workList/mei:work[1]//mei:titlePart[@type = 'desc']
            let $titleLang := $titleDesc/string(@xml:lang) 
            return <span xmlns="http://www.w3.org/1999/xhtml">{
                string-join(wega-util:transform($titleDesc, doc(concat($config:xsl-collection-path, '/works.xsl')), config:get-xsl-params(())), '. '),
                if($titleLang) then ' (' || $titleLang || ')'
                else ()
            }</span>
        }
        let $print-authors := function($doc as document-node(), $alt as xs:boolean) {
            for $author in ($doc//tei:sourceDesc/tei:biblStruct//tei:author)
            return <span xmlns="http://www.w3.org/1999/xhtml">{
                    wega-util:transform($author, doc(concat($config:xsl-collection-path, '/works.xsl')), config:get-xsl-params(()))
            }</span>
        }
        let $annotations := function($doc as document-node()) {
            for $note in ($doc//tei:notesStmt/tei:note|$doc//mei:notesStmt/mei:annot)
            return <span xmlns="http://www.w3.org/1999/xhtml">{wega-util:transform($note, doc(concat($config:xsl-collection-path, '/works.xsl')), config:get-xsl-params(()))}</span>
        }
        let $publication := function($doc as document-node(), $alt as xs:boolean) {
            for $pubDate in ($doc//tei:sourceDesc/tei:biblStruct//tei:date)
            return <span xmlns="http://www.w3.org/1999/xhtml">{$pubDate/string(@when)}</span>
        }
        let $pubPlace := function($doc as document-node(), $alt as xs:boolean) {
            for $pubPlace in ($doc//tei:sourceDesc/tei:biblStruct//tei:pubPlace)
            return <span xmlns="http://www.w3.org/1999/xhtml">
                    {if($pubPlace/@key)
                     then(<a href="/{$pubPlace/@key}.html" xmlns="http://www.w3.org/1999/xhtml">{$pubPlace/text()}</a>)
                     else($pubPlace/text())}
                </span>
        }
        let $publisher := function($doc as document-node(), $alt as xs:boolean) {
            for $segment in ($doc//tei:sourceDesc/tei:biblStruct//tei:publisher)
            return <span xmlns="http://www.w3.org/1999/xhtml">{
                    wega-util:transform($segment, doc(concat($config:xsl-collection-path, '/works.xsl')), config:get-xsl-params(()))
            }</span>
        }
        let $isPublishedIn := function($doc as document-node(), $alt as xs:boolean) {
            for $monogr in $doc//tei:sourceDesc/tei:biblStruct/tei:monogr
                let $files := crud:data-collection('biblio')[./tei:biblStruct/@xml:id = $monogr/@sameAs]
                for $file in $files/tei:biblStruct
                    let $id := $file/@xml:id
                    let $title := $file//tei:title[1]/text()
                    let $author := ($file//tei:author)[1]
                    let $type := $file/@type
                    let $year := if($file//tei:date/@when) then($file//tei:date/@when)
                                 else if($file//tei:biblscope[@unit='jg']) then($file//tei:biblscope[@unit='jg'])
                                 else if($file//tei:biblscope[@unit='nr']) then($file//tei:biblscope[@unit='nr'])
                                 else()
                    order by $year
                    return
                        <li xmlns="http://www.w3.org/1999/xhtml" year="{$year}"><a href="/{$id}.html">{string-join(($author,$title),': '), if($type) then(' (' || lang:get-language-string($type, $model('lang')) || ')') else()}</a></li>
        }
        let $workType := ($model?doc//(mei:term|mei:work[not(parent::mei:componentList)]|tei:biblStruct)[1]/(@class|@type)/data())[1]
        let $relators := query:relators($model?doc)[(self::mei:*|self::tei:*)/@role[not(. = ('edt'))] or self::tei:author or (self::mei:persName|self::mei:corpName)[@role][parent::mei:contributor]]
        let $relatorsGrouped := for $each in functx:distinct-deep($relators)
                                    let $role := $each/@role/string()
                                    group by $role
                                    return
                                        <relators role="{$role}">
                                            {$each}
                                        </relators>
        let $isPartOf := function($doc as document-node(), $linking as xs:boolean) {
            let $key := $model?doc//mei:relation[@rel="isPartOf"]/@codedval
            let $title := if($key) then(crud:doc($key/string())//mei:workList/mei:work[1]/mei:title/mei:titlePart[@type="main"]/text()) else()
            return
                <a href="/{$key}.html" xmlns="http://www.w3.org/1999/xhtml">{$title}</a>
        }
        let $hasParts := function($doc as document-node(), $linking as xs:boolean) {
            let $files := crud:data-collection('works')[.//mei:relation[@rel="isPartOf"][@codedval = $doc/mei:mei/@xml:id]]
            let $titles := for $file in $files/mei:mei
                            let $id := $file/@xml:id
                            let $title := $file//mei:workList/mei:work[1]/mei:title/mei:titlePart[@type="main"]/text()
                            return
                                <a href="/{$id}.html" xmlns="http://www.w3.org/1999/xhtml">{$title}</a>
            return
                $titles
        }
        let $hasComponents := function($doc as document-node(), $linking as xs:boolean) {
            for $component in $model?doc//mei:work[@class=('lp','cd')]/mei:componentList/mei:work
            let $title := $component/mei:title//text() => string-join(' ') => normalize-space()
            return
                $title
        }
        
        return
        map {
            'ids' : $model?doc//mei:altId[not(@type=('gnd', 'wikidata', 'dracor.einakter'))],
            'relatorGrps' : hwh-util:ordering-relators($relatorsGrouped),
            'workType' : $workType,
            'workTypeLabel' : if($workType) then(lang:get-language-string($workType, config:guess-language(()))) else(),
            'titles' : $print-titles($model?doc, false()),
            'authors' : $print-authors($model?doc, false()),
            'altTitles' : $print-titles($model?doc, true()),
            'descTitles' : $print-titles-desc($model?doc),
            'annotations' : $annotations($model?doc),
            'publication': $publication($model?doc, true()),
            'isPublishedIn': $isPublishedIn($model?doc, true()),
            'publisher': $publisher($model?doc, true()),
            'pubPlace': $pubPlace($model?doc, true()),
            'isPartOf' : $isPartOf($model?doc, true()),
            'hasParts' : $hasParts($model?doc, true()),
            'hasComponents' : $hasComponents($model?doc, true())
        }
};

declare 
    %templates:wrap
    function app:work-details($node as node(), $model as map(*)) as map(*) {
        map {
            'sources' : 
                if($config:isDevelopment) then core:getOrCreateColl('sources', $model('docID'), true())
                else (),
            'creation' : wega-util:transform(
                ($model?doc//mei:creation[not(parent::mei:expression)], $model?doc//mei:author[@type="textualSource"]), 
                doc(concat($config:xsl-collection-path, '/works.xsl')), 
                config:get-xsl-params( map {'dbPath' : document-uri($model?doc), 'docID' : $model?docID })
                ), 
            'dedicatees' : $model?doc//mei:fileDesc/mei:titleStmt/mei:respStmt/mei:persName[@role='dte'],
            'events' : wega-util:transform(
                ($model?doc//mei:eventList, $model?doc//tei:listEvent), 
                doc(concat($config:xsl-collection-path, '/works.xsl')), 
                config:get-xsl-params( map {'dbPath' : document-uri($model?doc), 'docID' : $model?docID })
                ), 
            'castList': wega-util:transform(
                $model?doc//mei:perfMedium/mei:castList,
                doc(concat($config:xsl-collection-path, '/works.xsl')), 
                config:get-xsl-params( map {'dbPath' : document-uri($model?doc), 'docID' : $model?docID })
                ),
            'perfResList': wega-util:transform(
                $model?doc//mei:perfMedium/mei:perfResList,
                doc(concat($config:xsl-collection-path, '/works.xsl')), 
                config:get-xsl-params( map {'dbPath' : document-uri($model?doc), 'docID' : $model?docID })
                ),
            'notesStmt': wega-util:transform(
                $model?doc//mei:notesStmt,
                doc(concat($config:xsl-collection-path, '/works.xsl')), 
                config:get-xsl-params( map {'dbPath' : document-uri($model?doc), 'docID' : $model?docID })
                ), 
            'backlinks' : core:getOrCreateColl('backlinks', $model('docID'), true()),
            'gnd' : query:get-gnd($model('doc')),
            'xml-download-url' : replace(controller:create-url-for-doc($model('doc'), $model('lang')), '\.html', '.xml')
        }
};

declare 
    %templates:wrap
    function app:prepare-work-id($node as node(), $model as map(*)) as map(*) {
        map {
            'id-key' : $model?id/@type,
            'id-value' : $model?id/text()
        }
};

(:
 : ****************************
 : Biblio pages
 : ****************************
:)

declare 
    %templates:wrap
    function app:biblio-basic-data($node as node(), $model as map(*)) as map(*) {
        let $lang := config:guess-language(())
        let $biblioType := $model?doc/tei:biblStruct/@type/data()
        let $biblioTypeLabel := if($biblioType) then(lang:get-language-string($biblioType, $lang)) else()
        let $print-authors := function($doc as document-node(), $alt as xs:boolean) {
            for $author in ($doc//tei:biblStruct/node()[1]/tei:author)
            return <span xmlns="http://www.w3.org/1999/xhtml">{
                    wega-util:transform($author, doc(concat($config:xsl-collection-path, '/works.xsl')), config:get-xsl-params(()))
            }</span>
        }
        let $annotations := function($doc as document-node()) {
            for $note in ($doc//tei:notesStmt/tei:note|$doc//mei:notesStmt/mei:annot)
            return <span xmlns="http://www.w3.org/1999/xhtml">{wega-util:transform($note, doc(concat($config:xsl-collection-path, '/works.xsl')), config:get-xsl-params(()))}</span>
        }
        let $publication := function($doc as document-node()) {
            let $dateFormat := function($lang as xs:string) { 
                if($biblioType = 'journal')
                then('[Y]')
                else(if ($lang = 'de') then '[D]. [MNn] [Y]'
                else '[MNn] [D], [Y]')
            }
            return
                for $pubDate in ($doc//tei:biblStruct/tei:*/tei:imprint/tei:date)
                    return <span xmlns="http://www.w3.org/1999/xhtml">{date:printDate($pubDate, $lang, lang:get-language-string#3, $dateFormat) => replace('vom ','') => replace('from ','') => replace(' bis ','–') => replace(' to ','–') => replace('unbekannt','') => replace('unknown','')}</span>
        }
        let $pubPlace := function($doc as document-node(), $alt as xs:boolean) {
            for $pubPlace in ($doc//tei:biblStruct/tei:*/tei:imprint/tei:pubPlace)
            return
                <span xmlns="http://www.w3.org/1999/xhtml">
                    {if($pubPlace/@key)
                     then(<a href="/{$pubPlace/@key}.html" xmlns="http://www.w3.org/1999/xhtml">{$pubPlace/text()}</a>)
                     else($pubPlace/text())}
                </span>
        }
        let $publisher := function($doc as document-node(), $alt as xs:boolean) {
            for $segment in ($doc//tei:biblStruct/tei:*/tei:imprint/tei:publisher[not(.='')])
            return <span xmlns="http://www.w3.org/1999/xhtml">{
                    wega-util:transform($segment, doc(concat($config:xsl-collection-path, '/works.xsl')), config:get-xsl-params(()))
            }</span>
        }
        let $relators := query:relators($model?doc)[self::tei:*/@role[not(. = ('edt'))] or self::tei:author]
        let $relatorsGrouped := for $each in functx:distinct-deep($relators)
                                    let $role := $each/@role/string()
                                    group by $role
                                    return
                                        <relators role="{$role}">
                                            {$each}
                                        </relators>
        let $isPartOf := function($doc as document-node(), $linking as xs:boolean) {
            let $key := $model?doc/tei:biblStruct/tei:monogr/@sameAs
            let $title := if($key) then(crud:doc($key/string())//tei:title[1]/text()) else()
            return
                <a href="/{$key}.html" xmlns="http://www.w3.org/1999/xhtml">{$title}{bibl:biblScope($model?doc/tei:biblStruct/tei:monogr, $lang)}</a>
        }
        let $hasParts := function($doc as document-node(), $linking as xs:boolean) {
            let $files := (crud:data-collection('biblio'), crud:data-collection('works'))[.//tei:monogr[@sameAs = $doc/tei:biblStruct/@xml:id]]
            let $items := for $file in ($files/tei:biblStruct,$files//tei:sourceDesc/tei:biblStruct)
                            let $id := if($file/@xml:id) then($file/@xml:id) else($file/ancestor::tei:TEI/@xml:id)
                            let $title := if($file//tei:title[1]/text()) then($file//tei:title[1]/text()) else(($file/ancestor::tei:*//tei:title[not(@level='s')])[1])
                            let $author := ($file//tei:author)[1]
                            let $type := $file/@type
                            let $year := if($file//tei:date/@when) then($file//tei:date/@when)
                                         else if($file//tei:biblscope[@unit='jg']) then($file//tei:biblscope[@unit='jg'])
                                         else if($file//tei:biblscope[@unit='nr']) then($file//tei:biblscope[@unit='nr'])
                                         else()
                            order by $year
                            return
                                <li xmlns="http://www.w3.org/1999/xhtml" year="{$year}"><a href="/{$id}.html">{string-join(($author,$title),': '), if($type) then(' (' || lang:get-language-string($type, $lang) || ')') else()}</a></li>
            
            
            return
                <xhtml:ol class="media">
					{for $item in $items
					    let $year := $item/@year
					    group by $year
					    order by $year
					    return
					        <li><strong>{$item/@year/substring(.,1,4)}</strong>
        						<ol>
        							{$item}
        						</ol>
    						</li>}
				</xhtml:ol>
        }
        
        return
        map {
            'ids' : $model?doc//tei:biblStruct,
            'relatorGrps' : hwh-util:ordering-relators($relatorsGrouped),
            'biblioType' : $biblioType,
            'biblioTypeLabel' : $biblioTypeLabel,
            'authors' : $print-authors($model?doc, false()),
            'annotations' : $annotations($model?doc),
            'publication' : $publication($model?doc),
            'publisher' : $publisher($model?doc, true()),
            'pubPlace' : $pubPlace($model?doc, true()),
            'isPartOf' : $isPartOf($model?doc, true()),
            'hasParts' : $hasParts($model?doc, true())
        }
};

declare 
    %templates:wrap
    function app:biblio-details($node as node(), $model as map(*)) as map(*) {
        map {
            'backlinks' : core:getOrCreateColl('backlinks', $model('docID'), true()),
            'gnd' : query:get-gnd($model('doc')),
            'xml-download-url' : replace(controller:create-url-for-doc($model('doc'), $model('lang')), '\.html', '.xml')
        }
};

(:
 : ****************************
 : Person pages
 : ****************************
:)

declare 
    %templates:wrap
    function app:person-title($node as node(), $model as map(*)) as xs:string {
        query:title($model('docID'))
};

declare 
    %templates:wrap
    function app:person-forename-surname($node as node(), $model as map(*)) as xs:string {
        wega-util:print-forename-surname-from-nameLike-element(($model?doc//tei:persName | $model?doc//tei:orgName)[@type='reg'])
};

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:person-basic-data($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        let $wegaSpecs := $model('doc')//tei:residence | $model('doc')//tei:label[.='Ort']/following-sibling::tei:desc/tei:*
        let $hendiSpecs := $model('doc')//tei:org//tei:settlement | $model('doc')//tei:org//tei:country
        let $residences := for $each at $i in ($wegaSpecs | $hendiSpecs)
                            let $return := if($each/@key)
                                            then(<a href="/{$each/@key}.html">{str:normalize-space($each)}</a>)
                                            else(<span>{$each}</span>)
                            return
                                ($return, if($i lt count(($wegaSpecs, $hendiSpecs))) then(',&#160;') else())
        let $isAssociatedWith := for $association in $model('doc')//(tei:relation[@name="isAssociatedWith"]|tei:affiliation/tei:*[@key])
                                    return
                                        <li><a href="/{$association/@key}.html" xmlns="http://www.w3.org/1999/xhtml">{crud:doc($association/@key)//(tei:persName|tei:orgName)[@type='reg']}</a></li>
        let $isAssociatedBy := for $association in (crud:data-collection('orgs')|crud:data-collection('persons'))[.//(tei:relation[@name="isAssociatedWith"]|tei:affiliation/tei:*)[@key=$model('docID')]]
                                  let $id := $association//(tei:person|tei:org)/@xml:id
                                  let $objectName := crud:doc($id)//(tei:persName|tei:orgName)[@type='reg']
                                  return
                                  <li><a href="/{$id}.html" xmlns="http://www.w3.org/1999/xhtml">{$objectName}</a></li>
        return
	        map{
	            'fullnames' : $model('doc')//tei:persName[@type = 'full'] ! string-join(str:txtFromTEI(., $lang), ''),
	            'pseudonyme' : $model('doc')//tei:persName[@type = 'pseud'] ! string-join(str:txtFromTEI(., $lang), ''),
	            'birthnames' : $model('doc')//tei:persName[@subtype = 'birth'] ! string-join(str:txtFromTEI(., $lang), ''),
	            'realnames' : $model('doc')//tei:persName[@type = 'real'] ! string-join(str:txtFromTEI(., $lang), ''),
	            'altnames' : 
	                (
	                $model('doc')//tei:persName[@type = 'alt'][not(@subtype)] ! string-join(str:txtFromTEI(., $lang), ''),  
	                $model('doc')//tei:orgName[@type = 'alt'] ! string-join(str:txtFromTEI(., $lang), '')
	                ),
	            'marriednames' : $model('doc')//tei:persName[@subtype = 'married'] ! string-join(str:txtFromTEI(., $lang), ''),
	            'birth' : exists($model('doc')//tei:birth[not(tei:date) or tei:date[not(@type)]]),
	            'baptism' : exists($model('doc')//tei:birth/tei:date[@type='baptism']),
	            'death' : exists($model('doc')//tei:death[not(tei:date) or tei:date[not(@type)]]),
	            'funeral' : exists($model('doc')//tei:death/tei:date[@type = 'funeral']),
	            'occupations' : $model('doc')//tei:occupation,
	            'residences' : $residences,
	            'states' : for $each in $model('doc')//tei:state[@type='orgType']//tei:term return lang:get-language-string('orgType.' || $each, $lang),
	            'bibls' : $model('doc')//tei:listBibl/tei:bibl,
	            'addrLines' : $model('doc')//tei:addrLine[ancestor::tei:affiliation[tei:orgName='Carl-Maria-von-Weber-Gesamtausgabe']],
	            'isAssociatedWith': $isAssociatedWith,
                'isAssociatedBy': $isAssociatedBy
	        }
};

declare 
    %templates:wrap
    function app:person-details($node as node(), $model as map(*)) as map(*) {
    map{
        'correspondence' : core:getOrCreateColl('letters', $model('docID'), true()),
        'diaries' : core:getOrCreateColl('diaries', $model('docID'), true()),
        'writings' : core:getOrCreateColl('writings', $model('docID'), true()),
        'works' : core:getOrCreateColl('works', $model('docID'), true()),
        'contacts' : core:getOrCreateColl('contacts', $model('docID'), true()),
        'biblio' : core:getOrCreateColl('biblio', $model('docID'), true()),
        'news' : core:getOrCreateColl('news', $model('docID'), true()),
        (:distinct-values(core:getOrCreateColl('letters', $model('docID'), true())//@key[ancestor::tei:correspDesc][. != $model('docID')]) ! crud:doc(.),:)
        'backlinks' : core:getOrCreateColl('backlinks', $model('docID'), true()),
        'thematicCommentaries' : core:getOrCreateColl('thematicCommentaries', $model('docID'), true()),
        'documents' : core:getOrCreateColl('documents', $model('docID'), true()),
        
        'source' : $model('doc')/tei:person/data(@source),
        'gnd' : query:get-gnd($model?doc),
        'viaf' : query:get-viaf($model?doc),
        'xml-download-url' : replace(controller:create-url-for-doc($model('doc'), $model('lang')), '\.html', '.xml')
        (:core:getOrCreateColl('letters', 'indices', true())//@key[.=$model('docID')]/root() | core:getOrCreateColl('diaries', 'indices', true())//@key[.=$model('docID')]/root() | core:getOrCreateColl('writings', 'indices', true())//@key[.=$model('docID')]/root() | core:getOrCreateColl('persons', 'indices', true())//@key[.=$model('docID')]/root(),:)
        (:                'xml-download-URL' : config:link-to-current-app($model('docID') || '.xml'):)
    }
};

(:~
 : Prepare Beacon Links for display on person and work pages
 : Called via AJAX
 :)
declare 
    %templates:wrap 
    function app:beacon($node as node(), $model as map(*)) as map(*) {
        let $gnd := query:get-gnd($model?doc)
        let $beaconMap := 
            if($gnd) then er:beacon-map($gnd, config:get-doctype-by-id($model('docID')))
            else map {}
        return
            map { 'beaconLinks': 
                    for $i in $beaconMap?*
                    order by $i?text => lower-case() collation "?lang=de;strength=primary"
                    return 
                        <a xmlns="http://www.w3.org/1999/xhtml" title="{map:keys($i)}" href="{$i?link}">{$i?text}</a>
            }
};

declare 
    %templates:default("lang", "en")
    function app:print-wega-bio($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:div)* {
        let $query-result:= app:inject-query($model?doc/*)
        let $bio := wega-util:transform($query-result//(tei:note[@type='bioSummary'] | tei:event[tei:head] | tei:note[parent::tei:org] | tei:note[parent::tei:place]), doc(concat($config:xsl-collection-path, '/persons.xsl')), config:get-xsl-params(()))
        return
            if(some $i in $bio satisfies $i instance of element()) then $bio
            else 
                element {node-name($node)} {
                    $node/@*,
                    if($bio instance of xs:string) then <p xmlns="http://www.w3.org/1999/xhtml">{$bio}</p>
                    else templates:process($node/node(), $model)
                }
};

declare 
    %templates:default("lang", "en")
    function app:print-corresp-intro($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:div)* {
        let $themComm:= app:inject-query($model?doc/*)
        let $intro := collection(config:get-option('dataCollectionPath') || '/thematicCommentaries')/node()[@xml:id=$themComm//tei:relation[@name='introduction']/@key]
        let $text-transformed := wega-util:transform($intro//tei:text//tei:div[@xml:lang=$lang][position() lt 5], doc(concat($config:xsl-collection-path, '/var.xsl')), config:get-xsl-params(()))
        return
            $text-transformed
};

declare 
    %templates:default("lang", "en")
    function app:print-corresp-intro-readmore($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:div)* {
        let $intro-id := app:inject-query($model?doc/*)//tei:relation[@name='introduction']/@key
        let $link-to-intro := '/' || $lang || '/' || $intro-id
        return
            <div xmlns="http://www.w3.org/1999/xhtml">
                <a href="{$link-to-intro}">Zum vollständigen Artikel</a>
            </div>
};

declare 
    %templates:wrap
    function app:printPlaceOfBirthOrDeath($node as node(), $model as map(*), $key as xs:string) as item()* {
    let $placeNames :=
        switch($key)
        case 'birth' return query:placeName-elements($model('doc')//tei:birth)
        case 'death' return query:placeName-elements($model('doc')//tei:death)
        default return ()
    return
        for $placeName at $count in wega-util-shared:order-by-cert($placeNames)
            let $preposition :=
                if(matches(normalize-space($placeName), '^(auf|bei|im)')) then ' ' (: Präposition 'in' weglassen wenn schon eine andere vorhanden :)
                else concat(' ', lower-case(lang:get-language-string('in', $model('lang'))), ' ')
            let $key := $placeName/@key
            return (
                <span xmlns="http://www.w3.org/1999/xhtml">{$preposition}
                    {if($key) then(<a href="/{$key}.html">{str:normalize-space($placeName)}</a>)
                     else(str:normalize-space($placeName))}
                    {if($count eq count($placeNames)) then ()
                     else concat(' ',lang:get-language-string('or', $model('lang')),' ')}
                </span>
            )
};

declare 
    %templates:wrap
    function app:printDatesOfBirthOrDeath($node as node(), $model as map(*), $key as xs:string) as item()* {
        let $dates :=
            switch($key)
            case 'birth' return $model('doc')//tei:birth/tei:date[not(@type)]
            case 'baptism' return $model('doc')//tei:birth/tei:date[@type = 'baptism']
            case 'death' return $model('doc')//tei:death/tei:date[not(@type)]
            case 'funeral' return $model('doc')//tei:death/tei:date[@type = 'funeral']
            default return ()
        let $orderedDates := wega-util-shared:order-by-cert($dates)
        let $julian-tooltip := function($date as xs:date, $lang as xs:string) as element(xhtml:sup)? {
            let $julian-date := date:gregorian2julian($date)
            let $formated-julian-date := 
                if($julian-date castable as xs:date) then date:format-date(xs:date($julian-date), $config:default-date-picture-string($lang), $lang)
                (: special case for Julian leap years :)
                else if(ends-with($julian-date, '-02-29')) then replace(
                    date:format-date(xs:date('1600' || substring($julian-date, 5)), $config:default-date-picture-string($lang), $lang),
                    '1600',
                    substring($julian-date, 1, 4)
                )
                else ()
            return
                if($formated-julian-date) then
                <sup xmlns="http://www.w3.org/1999/xhtml"
                    class="jul" 
                    data-toggle="tooltip" 
                    data-container="body" 
                    title="{concat(lang:get-language-string('julianDate', $lang), ': ', $formated-julian-date)}"
                    >greg.</sup>
                else ()
        }
        return (
            date:printDate($orderedDates[1], $model?lang, lang:get-language-string#3, $config:default-date-picture-string),
            if(($orderedDates[1])[@calendar='Julian'][@when]) then ($julian-tooltip(xs:date($orderedDates[1]/@when), $model?lang))
            else (),
            (
                if(count($orderedDates) gt 1) then (
                    ' (' || lang:get-language-string('otherSources', $model?lang) || ': ',
                    
                    for $date at $count in subsequence($orderedDates, 2)
                    return 
                        <span xmlns="http://www.w3.org/1999/xhtml">{
                            date:printDate($date, $model?lang, lang:get-language-string#3, $config:default-date-picture-string),
                            if($date[@calendar='Julian'][@when]) then ($julian-tooltip(xs:date($date/@when), $model?lang))
                            else (),
                            if($count < count($orderedDates) - 1) then ', '
                            else ()
                        }</span>,
                        
                    ')'
                )
                else ()
            )
        )
};

declare
    %templates:wrap
    function app:portrait-credits($node as node(), $model as map(*)) as item()* {
        if($model('portrait')('source') = 'Carl-Maria-von-Weber-Gesamtausgabe') then ()
        else (
            $model('portrait')('source'),
            if(contains($model('portrait')('linkTarget'), config:get-option('iiifImageApi'))) then ()
            else (<br xmlns="http://www.w3.org/1999/xhtml"/>, element xhtml:a {
                attribute href {$model('portrait')('linkTarget')},
                $model('portrait')('linkTarget')
            })
        )
};

(:~
 : Basic Data for Thematic Commentaries
 : 
 : @author Dennis Ried :)

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:thematicCommentary-basic-data($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        map{
            'authors' : $model('doc')//tei:fileDesc/tei:titleStmt/tei:author
            }
};

(:~
 : Basic Data for News
 : 
 : @author Dennis Ried :)

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:document-basic-data($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        map{
            'authors' : $model('doc')//tei:fileDesc/tei:titleStmt/tei:author
            }
};

(:
 : ****************************
 : Corresp pages
 : ****************************
 : @author: Dennis Ried
:)

declare 
    %templates:wrap
    function app:corresp-title($node as node(), $model as map(*)) as xs:string {
        query:title($model('docID'))
};

declare 
    %templates:default("lang", "en")
    %templates:default("popover", "false")
    function app:preview-correspPartner-name($node as node(), $model as map(*), $lang as xs:string, $popover as xs:string) as element() {
        let $key := $model('correspPartner')
        let $myPopover := wega-util-shared:semantic-boolean($popover)
        let $doc2key := crud:doc($key)
        return
            if($myPopover and $doc2key)
            then app:createDocLink($doc2key, $doc2key//(tei:persName|tei:orgName)[@type='reg'] ! string-join(str:txtFromTEI(., $lang), ''), $lang, (), true())
            else element xhtml:span {
                if($doc2key) then wdt:lookup(config:get-doctype-by-id($key), data($key))?title('txt')
                else str:normalize-space($model('correspPartner'))
            }
};

declare 
    %templates:default("lang", "en")
    %templates:default("popover", "true")
    function app:preview-editors($node as node(), $model as map(*), $lang as xs:string, $popover as xs:string) as element()* {
        let $keys := $model('editors')
        for $key in $keys
            let $myPopover := wega-util-shared:semantic-boolean($popover)
            let $doc2key := crud:doc($key)
                return
                    <li class="media editors" xmlns="http://www.w3.org/1999/xhtml">
						<span class="pull-left">
							<i class="fa fa-user"/>
						</span> {
                            if($myPopover and $doc2key)
                            then app:createDocLink($doc2key, $doc2key//(tei:persName|tei:orgName)[@type='reg'] ! string-join(str:txtFromTEI(., $lang), ''), $lang, (), true())
                            else element xhtml:span {
                                if($doc2key) then wdt:lookup(config:get-doctype-by-id($key), data($key))?title('txt')
                                else str:normalize-space($key)
                            }
                        }
					</li>
};

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:corresp-basic-data($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        let $search-results as document-node()* := core:getOrCreateColl('letters', $model('docID'), true())
        let $dates := $search-results//tei:correspDesc//tei:date
        let $datesStrings := for $date in $dates return date:getOneNormalizedDate($date, false())
        let $letterEarliest := if(count($datesStrings) gt 0) then(date:format-date(min($datesStrings), '[D]. [MNn] [Y]', $lang)) else()
        let $letterLatest := if(count($datesStrings) gt 0) then(date:format-date(max($datesStrings), '[D]. [MNn] [Y]', $lang)) else()
        let $correspPartners := for $value in distinct-values($search-results//tei:correspAction//(tei:persName|tei:orgName)/@key)
                                    order by crud:doc($value)//(tei:persName|tei:orgName)[@type='reg'] ! string-join(str:txtFromTEI(., $lang), '')
                                    return
                                        $value
        let $editors := for $value in distinct-values($search-results//tei:fileDesc//tei:editor/@key)
                                    order by crud:doc($value)//(tei:persName|tei:orgName)[@type='reg'] ! string-join(str:txtFromTEI(., $lang), '')
                                    return
                                        $value
        let $annotation := for $each in $model('doc')//tei:notesStmt/tei:note[@type = 'annotation']
                            let $eachLangSensitive := if($each/@xml:lang) then($each[@xml:lang=$lang]) else($each)
                            return
                                $eachLangSensitive/string()
        return
	        map{
	            'letterEarliest' : $letterEarliest,
	            'letterLatest' : $letterLatest,
	            'correspPartners' : $correspPartners,
	            'editors' : $editors,
	            'annotation' : $annotation
	        }
};

declare 
    %templates:wrap
    function app:corresp-details($node as node(), $model as map(*)) as map(*) {
	    map{
	        'correspondence' : core:getOrCreateColl('letters', $model('docID'), true()),
	        'documents' : core:getOrCreateColl('documents', $model('docID'), true()),
	        'works' : core:getOrCreateColl('works', $model('docID'), true()),
	        'places' : core:getOrCreateColl('places', $model('docID'), true()),
	        'xml-download-url' : replace(controller:create-url-for-doc($model('doc'), $model('lang')), '\.html', '.xml')
	    }
};


(:~
 : Main Function for wikipedia.html
 : Creates the wikipedia model
 :
 : @author Peter Stadler 
 : @return map with keys:('wikiContent','wikiUrl','wikiName')
 :)
declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:wikipedia($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        (: the return value of `er:wikipedia-article-url` is a sequence of URLs :)
        let $wikiUrl as xs:anyURI := (($model?doc//tei:idno        | $model?doc//mei:altId) => er:wikipedia-article-url($lang))[1]
        return
            er:wikipedia-article($wikiUrl,                $lang)
};


declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:wikipedia-text($node as node(), $model as map(*), $lang as xs:string) as item()* {
        let $wikiText := wega-util:transform($model('wikiContent')//xhtml:div[@id='bodyContent'], doc(concat($config:xsl-collection-path, '/wikipedia.xsl')), config:get-xsl-params(()))
        return 
            if(exists($wikiText)) then $wikiText
            else lang:get-language-string('failedToLoadExternalResource', $lang)
};

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:wikipedia-disclaimer($node as node(), $model as map(*), $lang as xs:string) as item()* {
        if($model('wikiContent')//xhtml:html) then 
            switch($lang) 
            case 'de' return (
                'Der Text unter der Überschrift „Wikipedia“ entstammt dem Artikel „',
                <a xmlns="http://www.w3.org/1999/xhtml" href='{$model('wikiUrl')}' title='Wikipedia Artikel zu "{$model('wikiName')}"'>{$model('wikiName')}</a>,
                '“ aus der freien Enzyklopädie ',
                <a xmlns="http://www.w3.org/1999/xhtml" href="http://de.wikipedia.org" title="Wikipedia Hauptseite">Wikipedia</a>, 
                ' und steht unter der ',
                <a xmlns="http://www.w3.org/1999/xhtml" href="http://creativecommons.org/licenses/by-sa/3.0/deed.de">CC-BY-SA-Lizenz</a>,
                '. In der Wikipedia findet sich auch die ',
                <a xmlns="http://www.w3.org/1999/xhtml" href="{concat(replace($model('wikiUrl'), 'wiki/', 'w/index.php?title='), '&amp;action=history')}" title='Autoren und Versionsgeschichte des Wikipedia Artikels zu "{$model('wikiName')}"'>Versionsgeschichte mitsamt Autorennamen</a>,
                ' für diesen Artikel.'
            )
            default return (
                'The text under the headline “Wikipedia” is taken from the article “',
                <a xmlns="http://www.w3.org/1999/xhtml" href='{$model('wikiUrl')}' title='Wikipedia article for {$model('wikiName')}'>{$model('wikiName')}</a>,
                '” from ',
                <a xmlns="http://www.w3.org/1999/xhtml" href="http://en.wikipedia.org">Wikipedia</a>,
                ' the free encyclopedia, and is released under a ',
                <a xmlns="http://www.w3.org/1999/xhtml" href="http://creativecommons.org/licenses/by-sa/3.0/deed.en">CC-BY-SA-license</a>,
                '. You will find the ',
                <a xmlns="http://www.w3.org/1999/xhtml" href="{concat(replace($model('wikiUrl'), 'wiki/', 'w/index.php?title='), '&amp;action=history')}" title="Authors and revision history of the Wikipedia Article for {$model('wikiName')}">revision history along with the authors</a>,
                ' of this article in Wikipedia.'
            )
        else ()
};


(:~
 : Main Function for ndb.html and adb.html
 : Creates the Deutsche Biographie model
 :
 : @author Peter Stadler 
 : @return map with key:'adbndbContent'
 :)
declare 
    %templates:wrap
    function app:deutsche-biographie($node as node(), $model as map(*)) as map(*) {
        let $gnd := query:get-gnd($model?doc)
        return 
            map {
                'adbndbContent' : 
                    if(er:lookup-gnd-from-beaconProvider('ndbBeacon', $gnd)) 
                    then er:grab-external-resource-via-beacon('ndbBeacon', $gnd)
                    else if($gnd and er:lookup-gnd-from-beaconProvider('adbBeacon', $gnd)) 
                    then er:grab-external-resource-via-beacon('adbBeacon', $gnd)
                    else ()
            }
};

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:deutsche-biographie-text($node as node(), $model as map(*), $type as xs:string, $lang as xs:string) as item()* {
        let $deutsche-biographie-text := 
            if($type = 'ndb') then wega-util:transform($model('adbndbContent')//xhtml:div[@id='ndbcontent'], doc(concat($config:xsl-collection-path, '/deutsche-biographie.xsl')), config:get-xsl-params(()))/node()
            else wega-util:transform($model('adbndbContent')//xhtml:div[@id='adbcontent'], doc(concat($config:xsl-collection-path, '/deutsche-biographie.xsl')), config:get-xsl-params(()))/node()
        return 
            if(exists($deutsche-biographie-text)) then $deutsche-biographie-text
            else lang:get-language-string('failedToLoadExternalResource', $lang)
};

declare 
    %templates:wrap
    function app:deutsche-biographie-disclaimer($node as node(), $model as map(*), $type as xs:string) as item()* {
        ($model('adbndbContent')//xhtml:p[preceding-sibling::xhtml:h4[@id=concat($type, 'content_zitierweise')]])[1]/node()
};

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:dnb($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        let $gnd := query:get-gnd($model('doc'))
        let $dnbContent := er:grabExternalResource('dnb', $gnd, ())
        let $dnbOccupations := 
            try { ($dnbContent//rdf:RDF/rdf:Description/gndo:professionOrOccupation//rdf:*[starts-with(@rdf:resource, 'https://d-nb.info')] ! er:resolve-rdf-resource(.))//gndo:preferredNameForTheSubjectHeading/str:normalize-space(.) }
        catch * { wega-util:log-to-file('warn', string-join(($err:code, $err:description), ' ;; ')) }
        let $subjectHeadings := 
            try { (($dnbContent//rdf:RDF/rdf:Description/gndo:broaderTermInstantial | $dnbContent//rdf:RDF/rdf:Description/gndo:formOfWorkAndExpression) ! er:resolve-rdf-resource(.))//gndo:preferredNameForTheSubjectHeading/str:normalize-space(.) }
        catch * { wega-util:log-to-file('warn', string-join(($err:code, $err:description), ' ;; ')) }
        return
            map {
                'docType' : config:get-doctype-by-id($model?docID),
                'dnbContent' : $dnbContent,
                'dnbName' : ($dnbContent//rdf:RDF/rdf:Description/gndo:preferredNameForThePerson/str:normalize-space(.), $dnbContent//rdf:RDF/rdf:Description/gndo:preferredNameForTheCorporateBody/str:normalize-space(.), $dnbContent//rdf:RDF/rdf:Description/gndo:preferredNameForThePlaceOrGeographicName/str:normalize-space(.)),
                'dnbBirths' : 
                    if($dnbContent//gndo:dateOfBirth castable as xs:date) then date:format-date($dnbContent//gndo:dateOfBirth, $config:default-date-picture-string($lang), $lang)
                    else if($dnbContent//gndo:dateOfBirth castable as xs:gYear) then date:formatYear($dnbContent//gndo:dateOfBirth, $lang)
                    else(),
                'dnbDeaths' : 
                    if($dnbContent//gndo:dateOfDeath castable as xs:date) then date:format-date($dnbContent//gndo:dateOfDeath, $config:default-date-picture-string($lang), $lang)
                    else if($dnbContent//gndo:dateOfDeath castable as xs:gYear) then date:formatYear($dnbContent//gndo:dateOfDeath, $lang)
                    else(),
                'dnbOccupations' : 
                    if($dnbContent//rdf:RDF/rdf:Description/gndo:professionOrOccupation or $dnbContent//rdf:RDF/rdf:Description/gndo:professionOrOccupationAsLiteral) then
                        ($dnbOccupations, $dnbContent//rdf:RDF/rdf:Description/gndo:professionOrOccupationAsLiteral/str:normalize-space(.))
                    else (),
                'biographicalOrHistoricalInformations' : $dnbContent//gndo:biographicalOrHistoricalInformation,
                'dnbOtherNames' : (
                    for $name in ($dnbContent//rdf:RDF/rdf:Description/gndo:variantNameForThePerson, $dnbContent//rdf:RDF/rdf:Description/gndo:variantNameForTheCorporateBody, $dnbContent//rdf:RDF/rdf:Description/gndo:variantNameForThePlaceOrGeographicName/str:normalize-space(.))
                    return
                        if(functx:all-whitespace($name)) then ()
                        else str:normalize-space($name)
                ),
                'gndDefinition' : $dnbContent//gndo:definition,
                'lang' : $lang,
                'dnbURL' : config:get-option('dnb') || $gnd,
                'preferredNameForTheWork' : $dnbContent//gndo:preferredNameForTheWork  ! str:normalize-space(.),
                'variantNamesForTheWork' : $dnbContent//gndo:variantNameForTheWork ! str:normalize-space(.),
                'subjectHeadings' : $subjectHeadings
            }
};

(:~
 : Output prettified ('censored') XML
 : This function is called by the AJAX template xml.html 
~:)
declare function app:xml-prettify($node as node(), $model as map(*)) {
        let $docID := $model('docID')
        let $serializationParameters := <output:serialization-parameters><output:method>xml</output:method><output:media-type>application/xml</output:media-type><output:indent>no</output:indent></output:serialization-parameters>
        let $doc :=
        	if(config:get-doctype-by-id($docID)) then crud:doc($docID)
        	else gl:spec($model('exist:path'))
        return
            if($config:isDevelopment) then serialize($doc, $serializationParameters)
            else serialize(wega-util:inject-version-info(wega-util:process-xml-for-display($doc)), $serializationParameters)
};

declare 
    %templates:default("lang", "en")
    function app:person-addrLine($node as node(), $model as map(*), $lang as xs:string) as item()* {
        switch ($model('addrLine')/@n)
        case 'email' return 
            element xhtml:a {
                attribute class {'obfuscate-email'},
                normalize-space($model('addrLine'))
            }
        case 'telephone' return (
            lang:get-language-string('tel',$lang) || ': ',
            element xhtml:a {
                attribute href {'tel:' || replace(normalize-space($model('addrLine')), '-|–|(\(0\))|\s', '')},
                normalize-space($model('addrLine'))
            }
        )
        default return (
            switch ($model('addrLine')/@n)
            case 'fax' return lang:get-language-string('fax',$lang) || ': '
            default return (),
            normalize-space($model('addrLine'))
        )
};

(:~
 : Add a disclaimer to our "FFFI-Fremddaten"
~:)
declare function app:external-data-disclaimer($node as node(), $model as map(*)) as map(*)? {
    if($model?source = 'WeGA' or $model?docType ne 'persons') then ()
    else
        let $external-data-url := 
            if($model?source = 'Bach') then
                if($model?doc//tei:idno[@type='bd'])
                then 'https://www.bach-digital.de/receive/' || $model?doc//tei:idno[@type='bd']
                else 'https://www.bach-digital.de'
            else ()
        let $external-data-text := 
            switch($model?source) 
            case 'Bach' return 'Bach digital'
            case 'MB' return (<i>Giacomo Meyerbeer. Briefwechsel und Tagebücher</i>, ', Bd. 1 (1960)')
            case 'BGA' return 'der Gesamtausgabe des Beethoven-Briefwechsels (1996–1998)'
            case 'LoB' return (<i>Albert Lortzing. Sämtliche Briefe</i>, ' (1995)')
            case 'SchTb' return 'der Ausgabe der Schumann-Tagebücher, Bd. 1 (1971)'
            case 'SchEnd' return (<i>Robert Schumann in Endenich (1854–1856)</i>, ', hg. von Bernhard R. Appel (2006)')
            case 'HoB' return 'der Edition von E. T. A. Hoffmanns Briefwechsel, hg. von Friedrich Schnapp (1967–1969)'
            case 'Wies' return 'einer CellistInnen-Datenbank von Christiane Wiesenfeldt'
            default return 'Fremddaten'
        return
            map {
                'external-data-url': $external-data-url,
                'external-data-text': $external-data-text
            }
};

declare function app:print-external-data-disclaimer($node as node(), $model as map(*)) as item()* {
    element {node-name($node)} {
        if($model?external-data-url) then attribute href {
            $model?external-data-url
        }
        else (),
        $model?external-data-text
    }
};

(:
 : ****************************
 : Document pages
 : ****************************
:)


declare 
    %templates:wrap
    function app:doc-details($node as node(), $model as map(*)) as map(*) {
        let $facs := query:facsimile($model?doc)
        let            $localFacsimiles :=                $facs[tei:graphic][not(@sameAs)] except $facs[tei:graphic[starts-with(@url, 'http')]]
                let $externalIIIFManifestFacsimiles := $facs[@sameAs]
        let $IIIFImagesMap := ($localFacsimiles | $externalIIIFManifestFacsimiles) ! app:create-IIIFImagesMap(., $model)
                return
            map {
                'facsimile' : $facs,
                'localFacsimiles' : $localFacsimiles,
                'externalIIIFManifestFacsimiles' : $externalIIIFManifestFacsimiles,
                'IIIFImagesMap': $IIIFImagesMap,
                'hasCreation' : exists($model?doc//tei:creation),
                'xml-download-url' : replace(controller:create-url-for-doc($model('doc'), $model('lang')), '\.html', '.xml'),
                'thematicCommentaries' : distinct-values($model('doc')//tei:note[@type='thematicCom']/@target/tokenize(., '\s+')),
                'backlinks' : wdt:backlinks(())('filter-by-person')($model?docID)
            }
};

(:~
 : Helper function for app:doc-details#2
 : This function creates a map object from a tei:facsimile element and provides the keys "url" and "canvasStartIndex"
 : iff the tei:facsimile element points to an IIIF manifest  
 :)
declare    %private    function app:create-IIIFImagesMap($facsimile as element(tei:facsimile), $model as map(*)) as map(*) {
        let $url :=
 if($facsimile/@sameAs) then $facsimile/@sameAs => normalize-space()
        else controller:iiif-manifest-id($facsimile)
    let $canvasStartIndex :=
        if($model?doc/tei:ab/@facs)
        (: special case for diaries; need to subtract -1 since Javascript starts counting with 0 and the tei:surfaces are starting at @n=1 :)
        then crud:data-collection('diaries')/id($model?doc/tei:ab/@facs => substring(2))/parent::tei:surface/@n => number() - 1
        else if($facsimile/tei:surface/@n)
        then $facsimile/tei:surface/@n
        else 0
    return
        map {
            "url": $url,
 "canvasStartIndex": $canvasStartIndex
 }
};

declare
 %templates:wrap
 function app:document-title($node as node(), $model as map(*)) as item()* {
        let $docID := $model('doc')/*/data(@xml:id) (: need to check because of index.html :)
        let $title := wdt:lookup(config:get-doctype-by-id($docID), $model('doc'))?title('html') 
        return
            if($title instance of xs:string) then $title
            else $title/node()
};

declare 
    %templates:wrap
    function app:prepare-text($node as node(), $model as map(*)) as map(*) {
        let $doc := $model('doc')
        let $docID := $model('docID')
        let $lang := $model('lang')
        let $docType := $model('docType')
        let $xslParams := config:get-xsl-params( map {
            'dbPath' : document-uri($doc),
            'docID' : $docID,
            'transcript' : 'true',
            'createSecNos' : if($docID = ('A070010', 'A070001F')) then 'true' else (),
            'collapse' : if(starts-with($docID,'A09')) then (true()) else (false())
            } )
        let $xslt1 := 
            switch($docType)
            case 'letters' case 'documents' return doc(concat($config:xsl-collection-path, '/letters.xsl'))
            case 'works' return doc(concat($config:xsl-collection-path, '/works.xsl'))
            case 'writings' return doc(concat($config:xsl-collection-path, '/document.xsl'))
            case 'diaries' return doc(concat($config:xsl-collection-path, '/diaries.xsl'))
            default  return doc(concat($config:xsl-collection-path, '/var.xsl'))
        let $textRoot :=
            switch($docType)
            case 'diaries' return $doc/tei:ab ! app:inject-query(.)
            case 'works' return $doc/mei:mei ! app:inject-query(.)
            case 'var' case 'addenda' case 'news' return ($doc//tei:text/tei:body ! app:inject-query(.))/(tei:div[@xml:lang=$lang] | tei:divGen | tei:div[not(@xml:lang)] | (if(not(tei:div[@xml:lang=$lang])) then(tei:div[@xml:lang]) else()) )
            case 'thematicCommentaries' return ($doc//tei:text/tei:body ! app:inject-query(.))/(tei:div[@xml:lang=$lang] | tei:div[not(@xml:lang)]) | $doc//tei:text/tei:back
            default return $doc//tei:text ! app:inject-query(.)
        let $body := 
             if(functx:all-whitespace(<root>{$textRoot}</root>))
             then 
                element xhtml:p {
                        attribute class {'notAvailable'},
                        (: revealed correspondence which has backlinks gets a direct link to the backlinks, see https://github.com/Edirom/WeGA-WebApp/issues/304 :)
                        if($doc//tei:correspDesc[@n = 'revealed'] and $model('backlinks')) then (
                            substring-before(lang:get-language-string('correspondenceTextNotAvailable', $lang),"."), ' ',
                            <span xmlns="http://www.w3.org/1999/xhtml">({lang:get-language-string('see', $lang)}</span>, ' ',
                            <span xmlns="http://www.w3.org/1999/xhtml"><a href="#backlinks">{lang:get-language-string('backlinks', $lang)}</a>).</span>, ' ',
                            substring-after(lang:get-language-string('correspondenceTextNotAvailable',$lang),".") )
                        (: … for revealed correspondence without backlinks drop that link :)
                        else if($doc//tei:correspDesc[@n = 'revealed']) then lang:get-language-string('correspondenceTextNotAvailable',$lang)
                        (: all other empty texts :)
                        else lang:get-language-string('correspondenceTextNotYetAvailable', $lang),
                        (: adding link to editorial :)
                        lang:get-language-string('forFurtherDetailsSee', $lang), ' ',
                        <a xmlns="http://www.w3.org/1999/xhtml" href="#editorial">{lang:get-language-string('editorial', $lang)}</a>, '.'
                }
             else (
                 (: adding link to editorial :)
                (: element xhtml:p {attribute style {'text-align: end;'}, lang:get-language-string('detailsAvailable', $lang), ': ', <a xmlns="http://www.w3.org/1999/xhtml" href="#editorial">{lang:get-language-string('generalRemark', $lang)}</a>, '.'}, :)
                if($doc//tei:notesStmt/tei:note[@type="editorial"][1])
                then(element xhtml:div {
                    attribute class {'alert alert-info text-center'},
         	        concat(lang:get-language-string('detailsAvailable', $lang), ': '), 
         	        element xhtml:a {
         	            attribute href {'#editorial'},
         	            concat(lang:get-language-string('generalRemark', $lang), '.')
                    }
             	})
             	else(),
                wega-util:transform($textRoot, $xslt1, $xslParams)
            )
         let $foot := 
            if(config:is-news($docID)) then app:get-news-foot($doc, $lang)
            else ()
         let $isRelatedAlert := if($doc//tei:relation[@name='isEnclosureOf']/@key)
                                  then(element xhtml:div {
                                    attribute class {'alert alert-primary text-center'},
                             	        lang:get-language-string('isEnclosureOf',$lang) || ' ',
                             	        element xhtml:b {
                             	            app:createDocLink(collection(config:get-option('dataCollectionPath'))//tei:TEI[@xml:id=$doc//tei:relation[@name='isEnclosureOf']/@key]/root(),$doc//tei:relation[@name='isEnclosureOf']/@key/string(),$lang,())
                             	        }
                                 	 })
                             	 else if ($doc//tei:relation[@name='isEnvelopeOf']/@key)
                                  then(element xhtml:div {
                                    attribute class {'alert alert-primary text-center'},
                             	        lang:get-language-string('isEnvelopeOf',$lang) || ' ',
                             	        element xhtml:b {
                             	            app:createDocLink(collection(config:get-option('dataCollectionPath'))//tei:TEI[@xml:id=$doc//tei:relation[@name='isEnvelopeOf']/@key]/root(),$doc//tei:relation[@name='isEnvelopeOf']/@key/string(),$lang,())
                             	        }
                                 	 })
                             	 else ()
         return 
            map {
                'isRelatedAlert' : $isRelatedAlert,
                'transcription' : (wega-util:remove-elements-by-class($body, 'apparatus'),$foot), 
                'apparatus' : $body/descendant-or-self::*[@class='apparatus']
            }
};

(:~
 : Search and highlight query strings in a document
 : Helper function for app:prepare-text()
 :
 : @param $input must be node() that is indexed by Lucene
 : @return if a hit was found in $input, an expanded copy of the $input with exist:match elements wrapping the hits. 
 :      If no hit was found, the initial $input is returned
 :)
declare %private function app:inject-query($input as node()) {
    let $q := request:get-parameter('q', '')
    return 
        if($q) then
            let $sanitized-query-string := str:strip-diacritics(str:normalize-space(str:sanitize(string-join($q, ' '))))
            let $query := search:create-lucene-query-element($sanitized-query-string)
            let $result := ft:query($input, $query) 
            return
                if($result) then $result ! kwic:expand(.)
                else $input
        else $input
};

declare 
    %templates:wrap
    function app:series($node as node(), $model as map(*)) as xs:string {
        str:normalize-space($model('doc')/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@level='s'])
};

declare %private function app:translate-resp($resp as node(), $lang as xs:string) as xs:string {
	if($lang = 'en')
	then(
		  switch ($resp)
		      case 'Übersetzung' return 'Translation'
		      case 'Übertragung' return 'Transcription'
		      case 'Kommentierung' return 'Commentary'
		      case 'Sprachliche Beratung' return 'Language advice'
		      default return $resp
	    )
	else($resp)
};

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:respStmts($node as node(), $model as map(*), $lang as xs:string) as element()* {
        functx:distinct-deep(
        let $respStmts := for $respStmt in $model?respStmts
        					return (
            					<dt xmlns="http://www.w3.org/1999/xhtml">{app:translate-resp($respStmt/tei:resp, $lang)}</dt>,
					            <dd xmlns="http://www.w3.org/1999/xhtml">{str:normalize-space(string-join($respStmt/tei:name, '; '))}</dd>
        							)
        let $trlDocs := collection(config:get-option('dataCollectionPath'))//tei:relation[@name='isTranslationOf'][@key=$model?docID]/root()
        for $trlDoc in $trlDocs
            let $trlRespStmt := $trlDoc//tei:respStmt[tei:resp[.='Übersetzung']]
            let $trlDocLang := $trlDoc//tei:profileDesc/tei:langUsage/tei:language/@ident => string()
            let $trlDocLang := switch ($trlDocLang)
                                case 'en' return 'gb'
                                default return $trlDocLang
            let $trlLang := element span { attribute class {'fi fi-' || $trlDocLang}}
            let $respLabel := app:translate-resp($trlRespStmt/tei:resp, $lang)
            let $respStmtsRelated := 
            	(<dt xmlns="http://www.w3.org/1999/xhtml">{$respLabel, '&#160;', $trlLang}</dt>,
                <dd xmlns="http://www.w3.org/1999/xhtml">{str:normalize-space(string-join($trlRespStmt/tei:name, '; '))}</dd>)
        return
            ($respStmts, $respStmtsRelated)
        )
};

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:editors($node as node(), $model as map(*), $lang as xs:string) as element()* {
        
        <dt xmlns="http://www.w3.org/1999/xhtml">{lang:get-language-string('editors', $lang)}</dt>,
		<dd xmlns="http://www.w3.org/1999/xhtml">{str:normalize-space(string-join($model?editors, '; '))}</dd>
        	
};

declare 
    %templates:wrap
    function app:textSources($node as node(), $model as map(*)) as map(*) {
    let $textSources := query:text-sources($model?doc)
    let $textSourcesCount := count($textSources)
    return
        map {
            'textSources' : $textSources | $textSources/tei:msFrag,
            'textSourcesCountString' : if($textSourcesCount > 1) then concat("in ", $textSourcesCount, " ", lang:get-language-string("textSources",$model('lang'))) else ""
        }
};


declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:print-Source($node as node(), $model as map(*), $key as xs:string) as map(*)* {
        let $witOrFragPreceding := $model($key)/parent::tei:witness/preceding-sibling::tei:witness | $model($key)/self::tei:msFrag/preceding-sibling::tei:msFrag
        let $titlePrefix := if($model($key)/self::tei:msFrag or $model($key)/parent::tei:witness) then string(count($witOrFragPreceding) + 1) || '.' else ''
        let $title := if($model($key)/self::tei:msFrag) then 'fragment' else 'textSource'
        let $sourceLink-content :=
            typeswitch($model($key))
                case element(tei:msFrag) return wega-util:transform($model($key)/tei:msIdentifier, doc(concat($config:xsl-collection-path, '/editorial.xsl')), config:get-xsl-params(()))
                case element(tei:msDesc) return wega-util:transform($model($key)/tei:msIdentifier, doc(concat($config:xsl-collection-path, '/editorial.xsl')), config:get-xsl-params(()))
                case element(tei:biblStruct) return bibl:printCitation($model($key), <xhtml:span class="biblio-entry"/>, $model('lang'))
                case element(tei:bibl) return <xhtml:a href="/{$model($key)/@key}">{bibl:printCitation(crud:doc($model($key)/@key)//tei:biblStruct, <xhtml:span/>, $model('lang'))}</xhtml:a>
                (:  :    let $processed := wega-util:transform($model($key), doc(concat($config:xsl-collection-path, '/document.xsl')), config:get-xsl-params(()))
                    return if ($processed instance of xs:string+) then <span xmlns="http://www.w3.org/1999/xhtml">{$processed}</span>
                    else $processed :)
                default return <span xmlns="http://www.w3.org/1999/xhtml" class="noDataFound">{lang:get-language-string('noDataFound',$model('lang'))}</span>
        let $sourceCategory := if($model($key)/@rend) then lang:get-language-string($model($key)/@rend,$model('lang')) else ()
        let $sourceData-content :=
            typeswitch($model($key))
                case element(tei:msFrag) return wega-util:transform($model($key)/tei:*[not(self::tei:msIdentifier)], doc(concat($config:xsl-collection-path, '/editorial.xsl')), config:get-xsl-params(()))
                case element(tei:msDesc) return wega-util:transform($model($key)/tei:*[not(self::tei:msIdentifier or self::tei:msFrag)], doc(concat($config:xsl-collection-path, '/editorial.xsl')), config:get-xsl-params(()))
                default return ()
        let $source-id := concat("source_",util:hash(generate-id($model($key)),'md5'))
        let $collapse := exists($sourceData-content) or exists($model($key)/tei:additional) or exists($model($key)/tei:relatedItem)
        return
            map {
                'title' : $titlePrefix || ' ' || lang:get-language-string($title,$model?lang),
                'collapse' : $collapse,
                'sourceLink' : concat("#",$source-id),
                'sourceId' : $source-id,
                'sourceLink-content' : $sourceLink-content,
                'sourceData-content' : $sourceData-content,
                'sourceCategory' : $sourceCategory
            }
};

declare 
    %templates:wrap
    function app:additionalSources($node as node(), $model as map(*)) as map(*) {
        (: tei:msDesc, tei:bibl, tei:biblStruct als mögliche Kindelemente von tei:additional/tei:listBibl :)
        map {
            'additionalSources' : $model('textSource')/tei:additional/tei:listBibl/tei:* | $model('textSource')/tei:relatedItem/tei:*[not(./self::tei:listBibl)] | $model('textSource')/tei:relatedItem/tei:listBibl/tei:* 
        }
};


(:~
 : Fetch all (external) facsimiles for a text source
 : that are not provided via IIIF, thus will be output 
 : as links in the editorial section 
 :)
declare 
    %templates:wrap
    function app:externalImageURLs($node as node(), $model as map(*)) as map(*) {
        map {
            (: intersect with $model?facsimile to only get allowed facsimiles :)
            'externalImageURLs' : (query:witness-facsimile($model?textSource) intersect $model?facsimile)/tei:graphic[starts-with(@url, 'http')]/data(@url) 
        }
};

(:~
 : Outputs the summary information of a TEI document
 :
:)
declare 
    %templates:default("lang", "en")
    function app:print-summary($node as node(), $model as map(*), $lang as xs:string) as element()* {
        let $revealedNote := 
            if($model('doc')//tei:correspDesc[@n = 'revealed']) then lang:get-language-string('correspondenceTextNotAvailable', $lang)
            else ()
        let $summary := 
            if(query:summary($model('doc'), $lang)) then wega-util:transform(query:summary($model('doc'), $lang), doc(concat($config:xsl-collection-path, '/editorial.xsl')), config:get-xsl-params(()))
            else '–'
        return (
            if(exists($summary) and (every $i in $summary satisfies $i instance of element())) then $summary
            else if($summary = '–' and $revealedNote) then <div xmlns="http://www.w3.org/1999/xhtml"><p>{$revealedNote}</p></div>
            else if($summary = '–' and $node/ancestor-or-self::xhtml:div[@data-template="app:preview"]) then ()
            else <div xmlns="http://www.w3.org/1999/xhtml"><p>{$summary}</p></div>
        )
};

(:~
 : surround HTML fragment with quotation marks  
 :
 : @param $items the HTML fragments (or strings) to enquote
 : @param $lang the language switch (en, de)
 :)
declare %private function app:enquote-html($items as item()*, $lang as xs:string) as item()*  {
    let $enquotedDummy := str:enquote('dummy', $lang)
    return (
        <xhtml:span class="marks_supplied">{substring-before($enquotedDummy, 'dummy')}</xhtml:span>,
        $items,
        <xhtml:span class="marks_supplied">{substring-after($enquotedDummy, 'dummy')}</xhtml:span>
    ) 
};

declare 
    %templates:default("lang", "en")
    %templates:default("generate", "false")
    function app:print-incipit($node as node(), $model as map(*), $lang as xs:string, $generate as xs:string) as element(xhtml:p)* {
        let $incipit := wega-util:transform(query:incipit($model('doc')), doc(concat($config:xsl-collection-path, '/editorial.xsl')), config:get-xsl-params(()))
        return 
            if(exists($incipit) and (every $i in $incipit satisfies $i instance of element())) then $incipit ! element xhtml:p { app:enquote-html(./xhtml:p/node(), $lang) }
            else element xhtml:p {
                if(exists($incipit)) then app:enquote-html($incipit, $lang)
                else if(wega-util-shared:semantic-boolean($generate) and not(functx:all-whitespace($model('doc')//tei:text/tei:body))) then app:enquote-html(app:compute-incipit($model?doc, $lang), $lang)
                else '–'
            }
};

(:~
 :  Compute the incipit for a text 
 :  Helper function for app:print-incipit()
 :
 :  Incipits for letters shall not be taken from the address or the opener, but only from the letter text (proper)
 :  The current implementation is more or less a stub and can be expanded …
 :
 :  @param $doc the TEI document to compute the incipit from
 :  @param $lang the current language (de|en)
 :)
declare %private function app:compute-incipit($doc as document-node(), $lang as xs:string) as xs:string? {
    let $myTextNodes := $doc//tei:text/tei:body/tei:div[not(@type='address')][not(tei:p/tei:figure)]/(* except tei:dateline except tei:opener except tei:head except tei:fw except tei:figDesc | text())
    return
        if(string-length(normalize-space(string-join($myTextNodes, ' '))) gt 20) then str:shorten-TEI($myTextNodes, 80, $lang)
        else str:shorten-TEI($doc//tei:text/tei:body, 80, $lang)
};

declare 
    %templates:default("lang", "en")
    function app:print-generalRemark($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:p)* {
        let $generalRemark := wega-util:transform(query:generalRemark($model('doc')), doc(concat($config:xsl-collection-path, '/editorial.xsl')), config:get-xsl-params(()))
        return 
            if(exists($generalRemark) and (every $i in $generalRemark satisfies $i instance of element())) then $generalRemark
            else element xhtml:p {
                if(exists($generalRemark)) then $generalRemark
                else '–'
            }
};

declare 
    %templates:default("lang", "en")
    function app:print-thematicCom($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:p)* {
        let $thematicCom := crud:doc(substring-after($model('thematicCom'), 'wega:'))
        return
            element { node-name($node) } {
                attribute href { controller:create-url-for-doc($thematicCom, $lang) },
                wdt:thematicCommentaries($thematicCom)('title')('html')
            }
};

declare 
    %templates:default("lang", "en")
    %templates:wrap
    function app:print-creation($node as node(), $model as map(*), $lang as xs:string) as item()* {
        if($model?hasCreation and $model('result-page-entry')) then wega-util:txtFromTEI($model('doc')//tei:creation)
        else if($model?hasCreation) then wega-util:transform($model('doc')//tei:creation, doc(concat($config:xsl-collection-path, '/editorial.xsl')), config:get-xsl-params(()))
        else '–'
};


declare
    %templates:default("lang", "en")
    %templates:wrap
    function app:check-apparatus($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        map {
            'incipit' : query:incipit($model('doc')),
            'summary' : query:summary($model('doc'), $lang),
            'generalRemark' : query:generalRemark($model('doc')),
            'authors' : if (count(query:get-author-element($model('doc'))) > 1 ) then
                for $author in query:get-author-element($model('doc')) return app:printCorrespondentName($author,$lang,'fs') else (),
            'editors' : if (count(query:get-editor-element($model('doc'))) > 0 ) then
                for $editor in query:get-editor-element($model('doc')) return app:printCorrespondentName($editor,$lang,'fs') else (),
            'respStmts': 
                switch($model('docType'))
                case 'diaries' return (
                    <tei:respStmt><tei:resp>Übertragung</tei:resp><tei:name>Dagmar Beck</tei:name></tei:respStmt>,
                    <tei:respStmt><tei:resp>Kommentar</tei:resp><tei:name>Dagmar Beck</tei:name><tei:name>Frank Ziegler</tei:name></tei:respStmt>
                    )
                default return $model('doc')//tei:respStmt[parent::tei:titleStmt]
        }
};


(:~
 : Add context information to the current model map
 : NB: If no context information is found, an empty sequence will be returned
 : effectively removing the HTML subtree under $node from the output.
 :)
declare 
    %templates:wrap
    function app:context($node as node(), $model as map(*)) as map(*)? {
        let $senderID := tokenize($model?('exist:path'), '/')[3]
        let $context := 
            switch($model?docType)
            case 'letters' return map:merge((
                query:context-relatedItems($model?doc), 
                query:correspContext($model?doc, $senderID)
            ))
            default return query:context-relatedItems($model?doc)
        return
            if(wega-util-shared:has-content($context)) 
            then map:merge(($context, map:entry('senderID', $senderID)))
            else ()
};

declare 
    %templates:default("lang", "en")
    function app:print-letter-context($node as node(), $model as map(*), $lang as xs:string) as item()* {
        let $letter := $model('letter-norm-entry')('doc')
        let $partner := 
            switch($model('letter-norm-entry')('fromTo')) 
            (: There may be multiple addressees or senders! :)
            case 'from' return ($letter//tei:correspAction[@type='sent']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name])[1]
            case 'to' return ($letter//tei:correspAction[@type='received']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name])[1]
            default return wega-util:log-to-file('error', 'app:print-letter-context(): wrong value for parameter &quot;fromTo&quot;: &quot;' || $model('letter-norm-entry')('fromTo') || '&quot;')
        let $normDate := query:get-normalized-date($letter)
        return (
            element xhtml:a {
                attribute href {controller:create-url-for-doc-in-context($letter, $lang, $model?senderID)},
                $normDate
            },
            ": ",
            lower-case(lang:get-language-string($model('letter-norm-entry')('fromTo'), $lang)),
            " ",
            app:printCorrespondentName($partner, $lang, 's')
        )
};

declare 
    %templates:default("lang", "en")
    function app:print-context-relatedItem($node as node(), $model as map(*), $lang as xs:string) as item()* {
        if($model?context-relatedItem?context-relatedItem-doc) 
        then app:createDocLink($model?context-relatedItem?context-relatedItem-doc, wdt:lookup(config:get-doctype-by-id($model?context-relatedItem?context-relatedItem-doc/*/data(@xml:id)), $model?context-relatedItem?context-relatedItem-doc)?title('txt'), $lang, ())
        else wega-util:log-to-file('warn', 'unable to process related items for ' || $model?docID)
};

declare 
    %templates:default("lang", "en")
    %templates:wrap
    function app:print-context-relatedItem-type($node as node(), $model as map(*), $lang as xs:string) as xs:string? {
        lang:get-language-string($model?context-relatedItem?context-relatedItem-type, $lang)
};

(:~
 : Create csLink element (see https://github.com/correspSearch/csLink for options)
 : wip!
 : @author Jakob Schmidt
 :)
declare 
    %templates:default("lang", "en")
    function app:csLink($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:div) {        
        let $doc := $model('doc')
        let $correspondent-1-key := tokenize($model?('exist:path'), '/')[3]
        let $correspondent-1-gnd := query:get-gnd($correspondent-1-key)
        let $correspondent-2-key := ($doc//tei:correspAction[@type = 'received']//@key[parent::tei:persName or parent::name or parent::tei:orgName])[1]
        let $correspondent-2-gnd := query:get-gnd($correspondent-2-key)
        let $gnd-uri := config:get-option("dnb") (: 'https://d-nb.info/gnd/' :)        
        (: Element-Parameter :)
        let $data-correspondent-1-id := if ($correspondent-1-gnd) then concat($gnd-uri,$correspondent-1-gnd) else ""
        let $data-correspondent-1-name :=
            (:if ($data-correspondent-1-id) then "" else:) 
            if ($correspondent-1-key) then query:title($correspondent-1-key) else ""
        let $data-correspondent-2-id := if ($correspondent-2-gnd) then concat($gnd-uri,$correspondent-2-gnd) else ""
        let $data-correspondent-2-name :=
            (:if ($data-correspondent-2-id) then "" else :)
            if ($correspondent-2-key) then query:title($correspondent-2-key) else ""
        let $data-start-date := query:get-normalized-date($doc)        
        return
            element { node-name($node) } {
            attribute id {"csLink"}, (: mandatory :)
            attribute data-correspondent-1-id {$data-correspondent-1-id},
            attribute data-correspondent-1-name {$data-correspondent-1-name},            
            attribute data-correspondent-2-id {$data-correspondent-2-id},
            attribute data-correspondent-2-name {$data-correspondent-2-name},           
            attribute data-start-date { $data-start-date},
            attribute data-end-date {$data-start-date},
            attribute data-range {"30"},
            attribute data-selection-when {"before-after"},
            attribute data-selection-span {"median-before-after"},
            attribute data-result-max {"4"},
            attribute data-exclude-edition {"#" || config:get-option('cmifID')},
            attribute data-language {$lang}            
}
};


(:~
 : Create dateline and author link for website news
 : (Helper Function for app:print-transcription)
 :
 : @author Peter Stadler
 : @param $doc the news document node
 : @param $lang the current language (de|en)
 : @return element html:p
 :)
declare %private function app:get-news-foot($doc as document-node(), $lang as xs:string) as element(xhtml:p)? {
    let $authorElems := query:get-author-element($doc)
    let $authorElemsCount := count($authorElems)
    let $dateFormat := 
        if ($lang = 'de') then '[FNn], [D]. [MNn] [Y]'
                          else '[FNn], [MNn] [D], [Y]'
    return 
        if($authorElemsCount gt 0) then 
            element xhtml:p {
                attribute class {'authorDate'},
                for $authorElem at $count in $authorElems
                return (
                    app:printCorrespondentName($authorElem, $lang, 'fs'),
                if($count le $authorElemsCount -2) then ', '
                    else if($count eq $authorElemsCount -1) then ' ' || lang:get-language-string('and', $lang) || ' '
                    else()
                ),
                concat(', ', date:format-date(xs:date($doc//tei:publicationStmt/tei:date/xs:dateTime(@when)), $dateFormat, $lang))
            }
        else()
};

(:~
 : Initialize rendering of the facsimile (if available) on document pages 
 : by writing a whitespace separated list of IIIF manifest URLs to the `@data-url` attribute
 : for a client side renderer. 
 :)
declare function app:init-facsimile($node as node(), $model as map(*)) as element(xhtml:div) {
    element {node-name($node)} {
        $node/@*[not(name()=('data-originalMaxSize', 'data-url'))],
        if(count($model?IIIFImagesMap) gt 0) 
 then (
            attribute {'data-url'} { normalize-space(
                string-join($model?IIIFImagesMap?url, ' ') 
                )},
 attribute {'data-canvasindex'} {normalize-space(
                string-join($model?IIIFImagesMap?canvasStartIndex, ' ') 
            )} 
        )
        else ()
    }
};


(:
 : ****************************
 : Searches
 : ****************************
:)


(:~
 : Write the sanitized query string into the search text input for reuse
 : and set the placeholder text for initial search box.
 : To be called from an HTML template.
~:)
declare
%templates:default("lang", "en")
    function app:search-input($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:input)* {
    let $placeholder := lang:get-language-string("searchTerm",$lang)
    return
    element {node-name($node)} {
        $node/@*[not(name(.) = ('value', 'placeholder'))],
        if($model('query-string-org') ne '') then attribute {'value'} {$model('query-string-org')}
        else (),
        attribute placeholder {$placeholder}
    }
};

declare 
    %templates:default("lang", "en")
    function app:search-filter($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:label)* {
        let $selected-docTypes := request:get-parameter('d', ()) 
        return 
            for $docType in $search:wega-docTypes
            let $class := 
                if(($docType, 'all') = $selected-docTypes or empty($selected-docTypes)) then normalize-space($node/@class) || ' active'
                else normalize-space($node/@class)
            let $displayTitle := lang:get-language-string($docType, $lang)
            order by $displayTitle
            return                
             element {node-name($node)} {
                 $node/@*[not(name(.) = 'class')],
                 attribute class {$class},
                 element input {
                     $node/xhtml:input/@*[not(name(.) = 'value')],
                     attribute value {$docType},
                     if(($docType, 'all') = $selected-docTypes or empty($selected-docTypes)) then attribute checked {'checked'}
                     else ()
                 },
                 <span xmlns="http://www.w3.org/1999/xhtml">{$displayTitle}</span>,
                 <a xmlns="http://www.w3.org/1999/xhtml" href="#" class="checkbox-only">{lang:get-language-string("only",$lang)}</a>
             }
};

(:~
 : Overwrites the current model with 'doc' and 'docID' of the preview document
 :
 :)
declare
    %templates:wrap
    %templates:default("lang", "en")
    function app:preview($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        let $workType := $model('result-page-entry')//((mei:term|mei:work[not(parent::mei:componentList)]|tei:biblStruct)[1]/(@class|@type))[1]
        let $biblioType := $model('result-page-entry')/tei:biblStruct/data(@type)
        let $biblioTypeLabel := if($biblioType) then(lang:get-language-string($biblioType, config:guess-language(()))) else()
        let $relators := query:relators($model('result-page-entry'))[self::mei:*/@role[. = ('cmp', 'lbt', 'lyr', 'arr')] or self::tei:*/@role[. = ('arr', 'trl')] or self::tei:author or (self::mei:persName|self::mei:corpName)[@role = 'mus'][parent::mei:contributor]]
        let $relatorsGrouped := for $each in functx:distinct-deep($relators)
                                    let $role := $each/@role/string()
                                    group by $role
                                    return
                                        <relators role="{$role}">
                                            {$each}
                                        </relators>
        return
            map {
            'doc' : $model('result-page-entry'),
            'docID' : $model('result-page-entry')/root()/*/data(@xml:id),
            'docURL' : 
                if(config:is-person($model?parent-docID)) then controller:create-url-for-doc-in-context($model?result-page-entry, $lang, $model?parent-docID)
                else controller:create-url-for-doc($model('result-page-entry'), $lang),
            'docType' : config:get-doctype-by-id($model('result-page-entry')/root()/*/data(@xml:id)),
            'relatorGrps' : hwh-util:ordering-relators($relatorsGrouped),
            'biblioType' : $biblioType,
            'biblioTypeLabel' : $biblioTypeLabel,
            'workType' : $workType,
            'workTypeLabel' : if($workType) then(lang:get-language-string($workType, $lang)) else(),
            'newsDate' : date:printDate($model('result-page-entry')//tei:date[parent::tei:publicationStmt], $lang, lang:get-language-string#3, $config:default-date-picture-string)
        }
};

declare
    %templates:wrap
    function app:preview-details($node as node(), $model as map(*)) as map(*) {
        map {
            'hasCreation' : exists($model('doc')//tei:creation),
            'summary' : app:print-summary($node, $model, $model?lang) => string-join('; ') => str:normalize-space()
        }
};

declare 
    %templates:default("lang", "en")
    function app:preview-title($node as node(), $model as map(*), $lang as xs:string) as element() {
        let $title := wdt:lookup(config:get-doctype-by-id($model('docID')), $model('doc'))?title('html')
        return
            element {node-name($node)} {
                $node/@*[not(name(.) = 'href')],
                if($node[self::xhtml:a])
                then attribute href {
                    $model?docURL || (
                        if(map:contains($model, 'query-string-org'))
                        then ('?q=' || string-join(($model?query-string-org, $model?query-docTypes), '&amp;d=')) 
                        else ()
                )}
                else (),
                if($title instance of xs:string or $title instance of text() or count($title) gt 1) 
                then $title
                else $title/node()
            }
};

declare 
    %templates:default("lang", "en")
    function app:preview-incipit($node as node(), $model as map(*), $lang as xs:string) as xs:string {
        app:print-incipit($node, $model, $lang, 'true') ! str:normalize-space(.)  => string-join('; ')
};

declare 
    %templates:default("lang", "en")
    function app:preview-citation($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:p)? {
        let $source := query:get-main-source($model('doc'))
        return 
            typeswitch($source)
            case element(tei:biblStruct) return 
                element {node-name($node)} {
                    $node/@*,
                    bibl:printCitation($source, <xhtml:p/>, $lang)/node()
                }
            default return ()
};

declare 
    %templates:wrap
    %templates:default("max", "200")
    function app:preview-teaser($node as node(), $model as map(*), $max as xs:string) as xs:string {
        let $lang := $model('lang')
        let $textXML := $model('doc')/tei:ab | (if($model('doc')//tei:body[.//tei:div[@xml:lang=$lang]]) then($model('doc')//tei:body//tei:div[@xml:lang=$lang]) else($model('doc')//tei:body)) | $model('doc')//mei:annot[@type='Kurzbeschreibung'] (: letzter Fall für sources :)
        return
            str:shorten-TEI($textXML, number($max), $model?lang)
};


declare 
    %templates:default("lang", "en")
    function app:preview-opus-no($node as node(), $model as map(*), $lang as xs:string) as element()? {
        if(count($model('doc')//mei:altId[not(@type=('gnd', 'wikidata', 'dracor.einakter'))]) gt 0) then 
            element {node-name($node)} {
                $node/@*[not(name(.) = 'href')],
                if($node[self::xhtml:a]) then attribute href {controller:create-url-for-doc($model('doc'), $lang)}
                else (),
                if(exists($model('doc')//mei:altId[@type='WeV'])) then concat('(WeV ', $model('doc')//mei:altId[@type='WeV'], ')') (: Weber-Werke :)
                else concat('(', $model('doc')//(mei:altId[not(@type=('gnd', 'wikidata', 'dracor.einakter'))])[1]/string(@type), ' ', $model('doc')//(mei:altId[not(@type=('gnd', 'wikidata', 'dracor.einakter'))])[1], ')') (: Fremd-Werke :)
            }
        else()
};

declare 
    %templates:default("lang", "en")
    function app:preview-subtitle($node as node(), $model as map(*), $lang as xs:string) as element()? {
        let $main-title := ($model?doc//mei:meiHead//mei:workList/mei:work[1]//mei:titlePart[@type='main'])[1]
        let $sub-titles := $model?doc//mei:meiHead//mei:workList/mei:work[1]//mei:titlePart[@type = 'sub'][string(@xml:lang) = $main-title/string(@xml:lang)]
        return 
            if($sub-titles) then
                element {node-name($node)} {
                    $node/@*,
                    data(
                        (: output the first matching subtitle :)
                        $sub-titles[1]
                    )
                }
            else ()
};

declare 
    %templates:default("lang", "en")
    function app:preview-titleDesc($node as node(), $model as map(*), $lang as xs:string) as element()? {
        let $main-title := ($model?doc//mei:meiHead//mei:workList/mei:work[1]//mei:titlePart[@type='main'])[1]
        let $desc-titles := $model?doc//mei:meiHead//mei:workList/mei:work[1]//mei:titlePart[@type = 'desc'][string(@xml:lang) = $main-title/string(@xml:lang)]
        return 
            if($desc-titles) then
                element {node-name($node)} {
                    $node/@*,
                    data(
                        (: output the first matching subtitle :)
                        $desc-titles[1]
                    )
                }
            else ()
};


declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:preview-relator-role($node as node(), $model as map(*), $lang as xs:string) as xs:string? {
        if($model('relatorGrp')/@role) then lang:get-language-string($model('relatorGrp')/data(@role), $lang)
        else if($model('relatorGrp')/node()/tei:author) then lang:get-language-string('aut', $lang)
        else wega-util:log-to-file('warn', 'app:preview-relator-role(): Failed to reckognize role')
};

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:preview-creation($node as node(), $model as map(*), $lang as xs:string) as xs:string? {
        if($model('doc')/mei:manifestation/mei:pubStmt) then string-join($model('doc')/mei:manifestation/mei:pubStmt/*, ', ')
        else if($model('doc')/mei:manifestation/mei:creation) then str:normalize-space($model('doc')/mei:manifestation/mei:creation)
        else ()
};


declare 
    %templates:default("lang", "en")
    %templates:default("popover", "false")
    function app:preview-relator-name($node as node(), $model as map(*), $lang as xs:string, $popover as xs:string) as element()* {
        
    for $relator at $i in $model('relatorGrp')/node()
        let $key := $relator/@codedval | $relator/@key
        let $myPopover := wega-util-shared:semantic-boolean($popover)
        let $doc2key := crud:doc($key)
        let $relators-translation-lang :=
        	if($relator/(self::mei:*|self::tei:*)[@role[. = 'trl'] and @label])
        	then(
	            if($relator/self::mei:*[@role[. = 'trl'] and @label])
	            then ('(' || lang:get-language-string('into', $lang) || ' ' || lang:get-language-string($relator/data(@label), $lang) || (if($lang = 'de') then ('e') else()) ||')')
	            else if($relator/self::tei:*[@role[. = 'trl'] and @label])
	            then ('(' || lang:get-language-string('into', $lang) || ' ' || lang:get-language-string($relator/data(@label), $lang) || (if($lang = 'de') then ('e') else()) ||')')
	            else wega-util:log-to-file('warn', 'app:preview-relator-trlLang(): Failed to reckognize label'))
            else()
        return
            if($myPopover and $doc2key)
            then (if($i gt 1)
                  then(element xhtml:span {' | '})
                  else(),
                  app:createDocLink(crud:doc($key), query:title($key), $lang, (), true()),
                  if($relators-translation-lang)
                  then(element xhtml:span {' ', $relators-translation-lang})
                  else())
            else element xhtml:span {
                if($i gt 1)
                    then(element xhtml:span {' | '})
                    else(),
                if($doc2key)
                    then wdt:lookup(config:get-doctype-by-id($key), data($key))?title('txt')
                    else (str:normalize-space($relator),
                if($relators-translation-lang)
                    then(element xhtml:span {' ', $relators-translation-lang})
                    else())
            }
};

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:register-title($node as node(), $model as map(*), $lang as xs:string) as xs:string {
        lang:get-language-string($model('docType'), $lang)
};

declare function app:register-dispatch($node as node(), $model as map(*)) {
    switch($model('docType'))
    case 'persons' return templates:include($node, $model, 'templates/ajax/contacts.html') (:case 'personsPlus':)
    case 'orgs' return templates:include($node, $model, 'templates/ajax/orgs.html')
    case 'letters' return templates:include($node, $model, 'templates/ajax/correspondence.html')
    default return templates:include($node, $model, 'templates/ajax/' || $model('docType') || '.html')
};

declare 
    %templates:wrap
    function app:letter-count($node as node(), $model as map(*)) as xs:integer? {
        query:correspondence-partners($model('docID'))($model('parent-docID'))
};

declare 
    %templates:wrap
    function app:error-settings($node as node(), $model as map(*)) as map(*) {
        map {
            'bugEmail' : config:get-option('bugEmail') 
        }
};

(:~
 : Inject the @data-api-base attribute at the given node
 :
 : The value is taken from the "openapi" object within $model. 
 : If this key is missing, it defaults to $config:openapi-config-path 
 : (see `config:api-base()`)
 :
 : @author Peter Stadler
 :)
declare function app:inject-api-base($node as node(), $model as map(*))  {
    let $api-base := config:api-base($model?openapi)
    return
        app-shared:set-attr($node, map:merge(($model, map {'api-base' : $api-base})), 'data-api-base', 'api-base')
};

(:~
 : Set "checked" attribute for user preferences switches
 : depending on the `$model?settings` property which is injected 
 : in view-html.xql.
 :)
declare function app:init-custom-switch($node as node(), $model as map(*)) as element(xhtml:input) {
    element {node-name($node)} {
        $node/@* except $node/@checked,
        if(wega-util-shared:semantic-boolean($model?settings($node/@id))) 
        then attribute checked {'checked'} 
        else (),
        $node/*
    }
};

declare function app:enrichtment-datasets($node as node(), $model as map(*))  {

let $collPersons := collection(config:get-option('dataCollectionPath') || '/persons')/tei:person
let $collOrgs := collection(config:get-option('dataCollectionPath') || '/orgs')/tei:org
let $collPlaces := collection(config:get-option('dataCollectionPath') || '/places')/tei:place
let $collWorks := collection(config:get-option('dataCollectionPath') || '/works')/mei:mei

(: Zusammenfassen der drei collections :)
let $collRef := $collPersons | $collOrgs | $collPlaces | $collWorks

let $collPostals := collection(config:get-option('dataCollectionPath') || '/letters')/tei:TEI[.//tei:text//tei:p]

                    
let $references := 
    (: Schleife (jeder Brief einzeln) :)
    for $letter at $n in $collPostals
        
        (: Variablen-Definitionen:)
        let $letterID := $letter/@xml:id
        let $keys := if(contains($letter//tei:text//@key, ' '))
                     then(tokenize($letter//tei:text//@key, ' '))
                     else($letter//tei:text//@key) (:[starts-with(., 'A00') or starts-with(., 'A13')]:)
        
        (: Finde refernzierte Datensätze, Schleife: jede Referenz einzeln suchen :)
        let $objectsRef := for $key in $keys
	                            (: Finde den relevanten Datensatz :)
	                            let $refRecord := $collRef/id($key)
	                            (: finde Status des Datensatzes heraus :)
	                            let $refStatus := $refRecord/string(@status)
	                            (: werfe einen Titel aus :)
	                            let $refLabel := if(not(starts-with($key, ('A00', 'A08', 'A13'))))
	                                             then(($refRecord//*:title)[1]//text() => string-join(' ') => normalize-space())
	                                             else if (starts-with($key, ('A00', 'A08', 'A13')))
	                                             then($refRecord//(tei:orgName | tei:persName | tei:placeName)[@type="reg"]//text() => string-join('') => normalize-space())
	                                             else('no title found')
	                            
	                            where $refStatus = 'proposed'
	                            return
	                                <tr id="{$refRecord/string(@xml:id)}">
      	                                <td><a href="/{$refRecord/string(@xml:id)}">{$refRecord/string(@xml:id)}</a></td>
      	                                <td>{$refLabel}</td>
      	                                <td>{$refStatus}</td>
	                                </tr>
        
        (:Rückgabe Wert der Schleife:)
        return
            $objectsRef
    
    let $referencesDistinct := functx:distinct-deep($references)
    (: Rückgabe der Referenzen :)
    
    return
        <div>
            <h1>Derzeit sind {count($referencesDistinct)} Datensätze anzureichern</h1>
            <div class="accordion" id="accordEnrichResults">
                { (: Schleife zum Sortieren :)
                let $prefixes := for $each in distinct-values($referencesDistinct) return substring($each, 1,3)
                for $prefix at $i in distinct-values($prefixes)
                    let $prefixResolved := switch ($prefix)
                                           case 'A00' return 'Persons'
                                           case 'A02' return 'Works'
                                           case 'A08' return 'Orgs'
                                           case 'A13' return 'Places'
                                           default return $prefix
                    let $refs := $referencesDistinct[starts-with(@id, $prefix)]
                    order by $prefix
                    return
                        <div name="group" prefix="{$prefix}">
                             <div class="card">
                                <div class="card-header" id="heading-{$i}">
                                  <h2 class="mb-0">
                                    <button class="btn btn-link btn-block text-left" type="button" data-toggle="collapse" data-target="#collapse-{$i}" aria-expanded="true" aria-controls="collapse-{$i}">
                                      {$prefix} | {$prefixResolved} ({count($refs)} Datensätze)
                                    </button>
                                  </h2>
                                </div>
                                <div id="collapse-{$i}" class="collapse" aria-labelledby="heading-{$i}" data-parent="#accordEnrichResults">
                                    <div class="card-body">
                                        <table style="width: 100%;">
                                            <tr>
                                              <th>ID</th>
                                              <th>Title</th> 
                                              <th>Status</th>
                                            </tr>
                                            {for $ref in $refs
                                        	   order by $ref/@id
                                        	   return
                                        	       $ref
                                            }
                                        </table>
                                    </div>
                                </div>
                             </div>
                        </div>
                }
            </div>
        </div>
};

declare function app:get-file-ids-for-enrichment($elems as node()*, $type as xs:string) as node()* {
	for $elem in $elems
	let $name := $elem/text()
	let $fileID := $elem/root()/node()/@xml:id/string()
	group by $name
	order by $name
	return
	    <tr>
              <td>{$name}</td>
              <td>
                  {for $each at $i in distinct-values($fileID)
        			return
        			    (<a href="/{$each}">{$each}</a>, if($i = count(distinct-values($fileID))) then() else (<span> | </span>))}
		    </td>
        </tr>
};

declare function app:get-file-ids-for-enrichment2($name as xs:string, $elems as node()*, $correspID as xs:string, $type as xs:string) as node()* {
    if($elems)
    then(
    <div name="{$name}">
             <div class="card">
                <div class="card-header" id="heading-{$correspID}-{$name}">
                  <h2 class="mb-0">
                    <button class="btn btn-link btn-block text-left" type="button" data-toggle="collapse" data-target="#collapse-{$correspID}-{$name}" aria-expanded="true" aria-controls="collapse-{$correspID}-{$name}">
                      {$name} ({count(functx:distinct-deep($elems))} Einträge)
                    </button>
                  </h2>
                </div>
                <div id="collapse-{$correspID}-{$name}" class="collapse" aria-labelledby="heading-{$correspID}-{$name}" data-parent="#accordEnrichResults">
                    <div class="card-body">
                        <table style="width: 100%;">
                            <tr>
                              <th>Title</th> 
                              <th>IDs</th>
                            </tr>
            {
                app:get-file-ids-for-enrichment($elems, $type)
            }
            </table>
                    </div>
                </div>
             </div>
        </div>
    )
    else()
};

declare function app:missing-keys-datasets($node as node(), $model as map(*))  {

let $corresps := crud:data-collection('corresp')

for $corresp in $corresps
    let $correspTitle := $corresp//tei:fileDesc/tei:titleStmt/tei:title[1]/text()
    let $correspID := $corresp/tei:TEI/@xml:id/string()
    
    let $colls :=  crud:data-collection('letters')/tei:TEI[.//tei:relation[@key=$correspID]] | crud:data-collection('documents')/tei:TEI[.//tei:relation[@key=$correspID]] | crud:data-collection('var')/tei:TEI

    let $placeElems := $colls//(tei:settlement|tei:placeName|tei:bloc|tei:region|tei:district|tei:geogName)[not(@key)][not(./tei:*)] | $colls//tei:country[not(@key)][not(./tei:*)][not(ancestor::tei:publisher)]
    let $persNameElems := $colls//(tei:persName|tei:rs[@type='person']|tei:name[@type='person'])[not(@key)][not(./tei:*)]
    let $orgNameElems := $colls//(tei:orgName|tei:rs[@type='org']|tei:name[@type='org'])[not(@key)][not(./tei:*)]
    let $workElems := $colls//(tei:rs[@type='work']|tei:name[@type='work'])[not(@key)][not(./tei:*)]
    
    return
        <div class="row">
            <div class="col-md-3 order-2 side-col"/>
            <div class="col-md-9 main-col">
                <h1>{$correspTitle}</h1>
                <div class="accordion" id="accordEnrichResults">
                    {app:get-file-ids-for-enrichment2('Werke', $workElems, $correspID, 'works'),
                    app:get-file-ids-for-enrichment2('Personen', $persNameElems, $correspID, 'persons'),
                    app:get-file-ids-for-enrichment2('Organisationen', $orgNameElems, $correspID, 'orgs'),
                    app:get-file-ids-for-enrichment2('Orte', $placeElems, $correspID, 'places')
                    }
                </div>
            </div>
        </div>
};

declare function app:guidelines-preview($node as node(), $model as map(*))  {

let $targets := for $each in xmldb:get-child-resources('/db/apps/HenDi-WebApp/guidelines/')
                    return
                        substring-before(substring-after($each, 'guidelines-de-'), '.html')

let $links := for $target in $targets
                return
                    <a xmlns="http://www.w3.org/1999/xhtml" class="btn btn-secondary" target="_blank" href="/guidelines/guidelines-de-{$target}.html" style="padding: 1em; margin-right: 0.6em;">{replace($target, 'hendi','')}</a>
return
    <div xmlns="http://www.w3.org/1999/xhtml">
        {for $link in $links
            let $linkName := $link/text()
            order by $linkName
            return
                $link
        }
     </div>
};

declare function app:letters-to-check($node as node(), $model as map(*))  {

let $collPostals := core:getOrCreateColl('letters', 'indices', true())/tei:TEI[.//tei:text//tei:p]
let $entries := for $letter at $n in $collPostals
			        let $letterID := $letter/string(@xml:id)
			        let $letterSentPers := $letter//tei:correspAction[@type='sent']/tei:persName/text()/normalize-space() => string-join(' | ')
			        let $letterSentDate := $letter//tei:correspAction[@type='sent']/tei:date[1]/text()
			        let $hasComments := $letter//tei:text//comment()
			        let $needsHeight := $letter//tei:objectDesc//tei:dimensions/tei:height/@quantity/number() = 0
			        let $needsWidth := $letter//tei:objectDesc//tei:dimensions/tei:width/@quantity/number() = 0
			        let $needsDimensions := $needsHeight = true() or $needsWidth = true()
			        let $messageComments := <i><span style="color: green;">Enthält Kommentare</span></i>
			        let $messageDimensions := <i><span style="color: red;">Abmessungen fehlen</span></i>
			        let $message := (if($hasComments) then($messageComments) else(),if($needsDimensions) then ($messageDimensions) else())
			        where exists($message)
			        return
			            <tr id="{$letterID}" date="{$letterSentDate}" sender="{$letterSentPers}" xmlns="http://www.w3.org/1999/xhtml" style="vertical-align: top; border-bottom: dashed 1px;">
			                  <td><a href="/{$letterID}">{$letterID}</a></td>
			                  <td>{$letterSentDate}</td>
			                  <td>{$letterSentPers}</td>
			                  <td>{if($hasComments)
			                       then($message, <ul style="list-style-type: square;">{for $comment in $hasComments return <li>{string($comment)}</li>}</ul>)
			                       else($message)
			                  }</td>
			            </tr>
    
    return
        <div xmlns="http://www.w3.org/1999/xhtml">
            <h1>Zu überprüfende Briefe</h1>
            <div class="accordion" id="accordEnrichResults">
                {for $sender at $i in distinct-values($entries/@sender)
                    let $entryCount := count($entries[@sender = $sender])
                    order by $sender
                    return
                        <div name="group" sender="{$sender}">
                             <div class="card">
                                <div class="card-header" id="heading-{$i}">
                                  <h2 class="mb-0">
                                    <button class="btn btn-link btn-block text-left" type="button" data-toggle="collapse" data-target="#collapse-{$i}" aria-expanded="true" aria-controls="collapse-{$i}">
                                      {$sender} ({$entryCount} Datensätze)
                                    </button>
                                  </h2>
                                </div>
                                <div id="collapse-{$i}" class="collapse" aria-labelledby="heading-{$i}" data-parent="#accordEnrichResults">
                                    <div class="card-body">
                                        <table style="width: 100%;">
                                            <tr>
                                              <th style="width: 10%">ID</th>
                                              <th style="width: 15%">Datum</th>
                                              <th style="width: 15%">Absender</th>
                                              <th>Bemerkung</th>
                                            </tr>
                                            {for $entry in $entries[@sender = $sender]
                                                order by $entry/@date
                                                return
                                                    $entry
                                            }
                                        </table>
                                    </div>
                                </div>
                             </div>
                        </div>
                }
            </div>
        </div>
};

declare function app:translation($node as node(), $model as map(*))  {
    let $doc := $model('doc')
    let $docID := $model('docID')
    let $docType := $model('docType')
    let $lang := $model('lang')
    let $trlDocs := collection(config:get-option('dataCollectionPath'))//tei:relation[@name='isTranslationOf'][@key=$model?docID]/root()
    let $xslt1 := doc(concat($config:xsl-collection-path, '/letters.xsl'))
    for $trlDoc at $z in $trlDocs
        let $trlLang := $trlDoc//tei:profileDesc/tei:langUsage/tei:language/@ident => string()
        let $textRoot := $trlDoc//tei:text
        let $xslParams := config:get-xsl-params( map {
                'dbPath' : document-uri($doc),
                'docID' : $docID,
                'lang' : $trlLang,
                'transcript' : 'true',
                'createSecNos' : ()
                } )
        let $head := (
                         if($config:isDevelopment)
                         then(
                             element xhtml:p {
                                attribute class {'float-right font-italic'},
                    			'ID: ' || $trlDoc/tei:TEI/@xml:id/string()
                                }
                         )
                         else (),
                         if($trlDoc//tei:notesStmt/tei:note[@type="editorial"][1])
                         then(
                                element xhtml:div {
            	                attribute class {'alert alert-primary text-center'},
            	         	        lang:get-language-string('generalRemark',$lang) || ': ',
            	         	        element xhtml:span {
            	         	            wega-util:transform($trlDoc//tei:notesStmt/tei:note[@type="editorial"][1], $xslt1, $xslParams)
            	         	        }
                	         	 }
                             )
                         else()
                     )
    
        let $body := 
             if(functx:all-whitespace(<root>{$textRoot}</root>))
             then 
                element xhtml:p {
                        attribute class {'notAvailable'}
                }
             else (
                wega-util:transform($textRoot, $xslt1, $xslParams)
            )
        let $foot := element xhtml:p {
                        attribute class {'float-right font-italic'},
            			lang:get-language-string('translationBy',$lang),
                        ' ',
                        $textRoot/root()//tei:respStmt[tei:resp[. = 'Übersetzung']]/tei:name => string-join('/')
                        }
        return
            <div class="tab-pane fade" id="translation-{$z}">
              {$head,(wega-util:remove-elements-by-class(wega-util:remove-elements-by-class($body, 'apparatus'), 'noteMarker'),$foot)}
            </div>
    
};

declare function app:enclosure($node as node(), $model as map(*))  {
    let $doc := $model('doc')
    let $docID := $model('docID')
    let $lang := $model('lang')
    let $docType := $model('docType')
    let $xslParams := config:get-xsl-params( map {
            'dbPath' : document-uri($doc),
            'docID' : $docID,
            'transcript' : 'true',
            'createSecNos' : ()
            } )
    let $xslt1 := doc(concat($config:xsl-collection-path, '/letters.xsl'))
    let $enclosures := collection(config:get-option('dataCollectionPath'))//tei:relation[@name='isEnclosureOf'][@key=$model?docID]/root()
    for $enclosure at $z in $enclosures
    	let $textRoot := $enclosure//tei:text
    	let $xslParams := config:get-xsl-params( map {
            'dbPath' : document-uri($doc),
            'docID' : $docID,
            'transcript' : 'true',
            'createSecNos' : (),
            'enclosure' : 'true'
            } )
    	let $body := 
	         if(functx:all-whitespace(<root>{$textRoot}</root>))
	         then 
	            element xhtml:p {
	                    attribute class {'notAvailable'}
	            }
	         else (
	             element xhtml:div {
	                attribute class {'alert alert-primary text-center'},
	         	        lang:get-language-string('previewDocument',$lang) || ' ',
	         	        element xhtml:b {
	         	            app:createDocLink($enclosure,lang:get-language-string('switchDocumentView',$lang),$lang,())
	         	        }
    	         	 },
	               wega-util:transform($textRoot, $xslt1, $xslParams))
	    return
	        <div class="tab-pane fade" id="enclosure-{$z}">
	          {wega-util:remove-elements-by-class(wega-util:remove-elements-by-class($body, 'apparatus'), 'noteMarker')}
	        </div>
};

declare function app:envelope($node as node(), $model as map(*))  {
    let $doc := $model('doc')
    let $docID := $model('docID')
    let $lang := $model('lang')
    let $docType := $model('docType')
    let $xslParams := config:get-xsl-params( map {
            'dbPath' : document-uri($doc),
            'docID' : $docID,
            'transcript' : 'true',
            'createSecNos' : ()
            } )
    let $xslt1 := doc(concat($config:xsl-collection-path, '/letters.xsl'))
    let $envelopes := collection(config:get-option('dataCollectionPath'))//tei:relation[@name='isEnvelopeOf'][@key=$model?docID]/root()
    for $envelope at $z in $envelopes
    	let $textRoot := $envelope//tei:text
    	let $body := 
	         if(functx:all-whitespace(<root>{$textRoot}</root>))
	         then 
	            element xhtml:p {
	                    attribute class {'notAvailable'}
	            }
	         else (
	         	element xhtml:div {
	                attribute class {'alert alert-primary text-center'},
	         	        lang:get-language-string('previewDocument',$lang) || ' ',
	         	        element xhtml:b {
	         	            app:createDocLink($envelope,lang:get-language-string('switchEnvelopeView',$lang),$lang,())
	         	        }
    	         	 },
             	 wega-util:transform($textRoot, $xslt1, $xslParams))
	    return
	        <div class="tab-pane fade" id="envelope-{$z}">
	          {wega-util:remove-elements-by-class(wega-util:remove-elements-by-class($body, 'apparatus'), 'noteMarker')}
	        </div>
};

declare function app:credits($node as node(), $model as map(*)) as map(*) {
	map {
		'credits' : <p>{$model('doc')//tei:licence[@n='credits']/text()}</p>
	}
};

declare 
    %templates:default("lang", "en")
    %templates:default("popover", "false") function app:creditsEdition($node as node(), $model as map(*), $lang as xs:string, $popover as xs:string) as element()* {
	let $collections := (crud:data-collection('letters') | crud:data-collection('documents'))
	let $persons := $collections//tei:respStmt/tei:name[normalize-space(.) != '']
	let $orgs := $collections//tei:repository/tei:orgName/normalize-space() => distinct-values()
	let $successionItems := $collections//tei:licence[@n="credits"]/normalize-space() => distinct-values()
		
	let $personsOutput :=
		for $person in $persons
	        let $key := $person/@key
	        let $myPopover := wega-util-shared:semantic-boolean($popover)
	        let $doc2key := crud:doc($key)
	        let $resps := for $each in distinct-values($persons[. = $person]/parent::tei:respStmt/tei:resp)
	                        order by $each
	                        return $each
	        order by $person
	        return
	            <li>
	                <span>{
    	            	if($myPopover and $doc2key)
    		            then (app:createDocLink($doc2key, query:title($key), $lang, (), true()))
    		            else element xhtml:span {
    		                if($doc2key)
    		                then wdt:lookup(config:get-doctype-by-id($key), data($key))?title('txt')
    		                else (str:normalize-space($person))
    		            }
    		        }</span>
    		        <span>&#160;</span>
    		        <span>({string-join($resps, ', ')})</span>
		        </li>
    let $orgsOutput :=
		for $org in $orgs
	        order by $org
	        return
	            <li>{$org}</li>
	let $successionOutput :=
		for $successionItem in $successionItems
		    let $successionItemSwitched := switch($successionItem)
		                                    case 'By courtesy of the Estate of W. H. Auden.' return 'Courtesy of the Estate of W. H. Auden'
		                                    case 'By courtesy of the Estate of Chester Kallman.' return 'Courtesy of the Estate of Chester Kallman'
		                                    case 'By courtesy of the Estate of W. H. Auden and Chester Kallman.' return 'Courtesy of the Estate of W. H. Auden and Chester Kallman'
		                                    case 'Mit freundlicher Genehmigung der Rechtsnachfolge Friedrich Hitzer.' return 'Rechtsnachfolge Friedrich Hitzer'
		                                    case 'Mit freundlicher Genehmigung der Hans Werner Henze-Stiftung (Dr. Michael Kerstan).' return 'Hans Werner Henze-Stiftung (Dr. Michael Kerstan)'
		                                    case 'Mit freundlicher Genehmigung der Erbengemeinschaft Hans Magnus Enzensberger.' return 'Erbengemeinschaft Hans Magnus Enzensberger'
		                                    case 'Mit freundlicher Genehmigung der Paul Sacher Stiftung.' return 'Paul Sacher Stiftung'
		                                    case 'Mit freundlicher Genehmigung der Rechtsnachfolge.' return ''
		                                    default return $successionItem
	        order by $successionItemSwitched
	        return
	            <li>{$successionItemSwitched}</li>
    return
        (<div>
            <strong>{lang:get-language-string('persons', $lang)}</strong>
            <ul class="tei_simpleList">{functx:distinct-deep($personsOutput)}</ul>
            <strong>{lang:get-language-string('orgs', $lang)}</strong>
            <ul class="tei_simpleList">{$orgsOutput}</ul>
            <strong>{lang:get-language-string('legalSuccession', $lang)}</strong>
            <ul class="tei_simpleList">{$successionOutput}</ul>
        </div>)
};

declare function app:legalNotice($node as node(), $model as map(*)) as map(*) {
	map {
	    'legalNotice' : <p>{$model('doc')//tei:licence[@n='legalNote']/text()}</p>
	}
};

declare function app:download-modal($node as node(), $model as map(*))  {
		if(exists($model('doc')//tei:availability/tei:licence[. = 'noDownload']) = true())
		then templates:include($node, $model, 'templates/includes/download-modal-restricted.html')
		else templates:include($node, $model, 'templates/includes/download-modal-tei.html')
};

declare function app:zenodoDOIs($node as node(), $model as map(*)) {
<li>
	Zenodo: <a target="_blank" href="https://doi.org/{config:get-option('zenodoDoiData')}">Data</a> | 
	<a target="_blank" href="https://doi.org/{config:get-option('zenodoDoiOdd')}">TEI-ODD</a> | 
	<a target="_blank" href="https://doi.org/{config:get-option('zenodoDoiWebApp')}">WebApp</a>
</li>
};