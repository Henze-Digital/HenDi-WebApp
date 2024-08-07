xquery version "3.1" encoding "UTF-8";

(:~
: XQuery functions for fetching and manipulating images
:
: @author Peter Stadler 
:)

module namespace img="http://xquery.weber-gesamtausgabe.de/modules/img";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace wd="http://www.wikidata.org/prop/direct/";
declare namespace rdfs="http://www.w3.org/2000/01/rdf-schema#";
declare namespace dbp="http://dbpedia.org/property/";
declare namespace dbo="http://dbpedia.org/ontology/";
declare namespace foaf="http://xmlns.com/foaf/0.1/";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace sr="http://www.w3.org/2005/sparql-results#";
declare namespace wega="http://www.weber-gesamtausgabe.de";
declare namespace templates="http://exist-db.org/xquery/html-templating";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";

import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace hwh-util="http://henze-digital.zenmem.de/modules/hwh-util" at "hwh-util.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";
import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "wdt.xqm";
import module namespace controller="http://xquery.weber-gesamtausgabe.de/modules/controller" at "controller.xqm";
import module namespace er="http://xquery.weber-gesamtausgabe.de/modules/external-requests" at "external-requests.xqm";
(:import module namespace image="http://exist-db.org/xquery/image" at "java:org.exist.xquery.modules.image.ImageModule";:)
import module namespace functx="http://www.functx.com";

(:
Person portraits
thumb = x52
small = x60
large = x340
:)


(:~
 : Main function for creating a map of all images (from various sources)
 : for a given entity.
~:)
declare 
    %templates:default("lang", "en")
    %templates:wrap
    function img:iconography($node as node(), $model as map(*), $lang as xs:string) as map(*)? {
        let $docType := config:get-doctype-by-id($model?docID)
        let $func := 
            try { function-lookup(xs:QName('img:iconography4' || $docType), 3) } 
            catch * { wega-util:log-to-file('error', 'Failed to lookup iconography-function for ' || $docType ) }
        return 
            if(exists($func)) then $func($node, $model, $lang)
            else wega-util:log-to-file('debug', 'Missing iconography-function for ' || $docType )
};

(:~
 : Helper function for img:iconography()
 : Creates the iconography for persons
 :
~:)
declare %private function img:iconography4persons($node as node(), $model as map(*), $lang as xs:string) as map(*) {
    let $local-image := img:wega-images($model, $lang)
    let $suppressWikipediaPortrait := core:getOrCreateColl('iconography', $model('docID'), true())//tei:figure[not(tei:graphic)]
    let $portraitindex-images := img:portraitindex-images($model, $lang)
    let $wikipedia-images := 
        if(not($suppressWikipediaPortrait)) then img:wikipedia-images($model, $lang)
        else ()
    let $tripota-images := img:tripota-images($model, $lang)
    let $munich-stadtmuseum-images := img:munich-stadtmuseum-images($model, $lang)
    let $iconographyImages := ($local-image, $wikipedia-images, $portraitindex-images, $tripota-images, $munich-stadtmuseum-images)
    let $portrait := ($iconographyImages, img:get-generic-portrait($model, $lang))[1]
    return
        map { 
            'iconographyImages' : $iconographyImages,
            'portrait' : $portrait
        }
};

(:~
 : Helper function for img:iconography()
 : Creates the iconography for places
 :
~:)
declare %private function img:iconography4places($node as node(), $model as map(*), $lang as xs:string) as map(*) {
    let $local-images := img:wega-images($model, $lang)
    let $wikidata-images := img:wikidata-images($model, $lang)
    let $coa := 
        for $map in $wikidata-images 
        return 
            if($map?coa) then $map 
            else ()
    let $bildindex-images :=
        (: 
          only request Bildindex-images for single view (not list views) 
          since we're not able to cache these requests 
        :)
        if($node/@id='meta') 
        then img:bildindex-images($model, $lang)
        else ()
    return
        map { 
                'iconographyImages' : ($local-images, $wikidata-images, $bildindex-images),
                'portrait' : ($coa, $local-images, $wikidata-images, $bildindex-images, img:get-generic-portrait($model, $lang))[1]
            }
};

(:~
 : Helper function for img:iconography()
 : Creates the iconography for organizations
 :
~:)
declare %private function img:iconography4orgs($node as node(), $model as map(*), $lang as xs:string) as map(*) {
    img:iconography4persons($node, $model, $lang)
};

(:~
 : Helper function for img:iconography()
 : Creates the iconography for works
 :
~:)
declare %private function img:iconography4works($node as node(), $model as map(*), $lang as xs:string) as map(*) {
    let $wikidata-images := img:wikidata-images($model, $lang)
    return 
    map { 
        'iconographyImages' : $wikidata-images,
        'portrait' : ($wikidata-images, img:get-generic-portrait($model, $lang) )[1]
    }
};


(:~
 : Function for outputting an image from the iconography
 :
 : @return an HTML element <a> with a nested <img> or <i> element
~:)
declare function img:iconographyImage($node as node(), $model as map(*)) as element(a) {
    <xhtml:a href="{$model('iconographyImage')('linkTarget')}">{
        if(exists($model('iconographyImage')('url')('thumb')))
        then
            <xhtml:img 
                title="{$model('iconographyImage')('caption')}" 
                alt="{$model('iconographyImage')('caption')}" 
                src="{$model('iconographyImage')('url')('thumb')}"/>
 else <xhtml:i class="fa-regular fa-image fa-2xl"/>
    }</xhtml:a>
};

(:~
 : Helper function for img:iconography()
 : Creates the iconography for corresp
 :
 : @author Dennis Ried
~:)
declare %private function img:iconography4corresp($node as node(), $model as map(*), $lang as xs:string) as map(*) {
    let $wikidata-images := img:wikidata-images($model, $lang)
    return 
    map { 
        'iconographyImages' : $wikidata-images,
        'portrait' : ($wikidata-images, img:get-generic-portrait($model, $lang) )[1]
    }
};

(:~
 : Helper function for img:iconography()
 : Creates the iconography for biblio
 :
 : @author Dennis Ried
~:)
declare %private function img:iconography4biblio($node as node(), $model as map(*), $lang as xs:string) as map(*) {
    let $wikidata-images := img:wikidata-images($model, $lang)
    return 
    map { 
        'iconographyImages' : $wikidata-images,
        'portrait' : ($wikidata-images, img:get-generic-portrait($model, $lang) )[1]
    }
};

(:~
 : Helper function for grabbing images from wikidata
 :
 : @author Peter Stadler 
 : @param $model a map with all necessary variables, e.g. docID
 : @param $lang the language variable (de|en)
 :)
declare %private function img:wikidata-images($model as map(*), $lang as xs:string) as map(*)* {
    let $idno := $model?doc//tei:idno[@type=('gnd', 'viaf', 'geonames')] | $model?doc//mei:altId[@type=('gnd', 'viaf')]
    let $wikidataResponse := $idno ! er:grab-external-resource-wikidata(., ./@type)
    
    let $coa-filename := $wikidataResponse//sr:binding[@name=('wappenbild')] ! img:prep-wikimedia-image-filenames(.) 
    let $other-filenames := distinct-values($wikidataResponse//sr:binding[@name=('flaggenbild', 'image')]) ! img:prep-wikimedia-image-filenames(.)
    
    let $maps := img:wikimedia-api-imageinfo(($coa-filename, $other-filenames), $lang)
    return
        for $i in $maps
        return
            if(contains($i?caption, $coa-filename))
            then map:put($i, 'coa', true()) (: special treatment for coat of arms which will become the main (portrait) image :)
            else $i
};

(:~
 : Helper function for grabbing images from a wikipedia article 
 :
 : @author Peter Stadler 
 : @param 
 : @param $lang the language variable (de|en)
 : @return 
 :)
declare %private function img:wikipedia-images($model as map(*), $lang as xs:string) as map(*)* {
    let $wikiModel := ($model?doc//tei:idno | $model?doc//mei:altId) => er:wikipedia-article-url($lang) => er:wikipedia-article($lang)
    let $wikiArticle := $wikiModel?wikiContent 
    (: Look for images in wikipedia infobox (for organizations and english wikipedia) and thumbnails  :)
    let $images := 
        $wikiArticle//xhtml:td[contains(@class, 'infobox-image')]//xhtml:img |
 $wikiArticle//xhtml:figure[@typeof='mw:File/Thumb']//xhtml:img
    return 
        for $img in $images
        let $tmpPicURI := ($img/@src)[1]
        let $thumbURI := (: Achtung: in $pics landen auch andere Medien, z.B. audio. Diese erzeugen dann aber ein leeres $tmpPicURI, da natürlich kein <img/> vorhanden :)
            if(starts-with($tmpPicURI, '//')) then concat('https:', $tmpPicURI) 
            else if(starts-with($tmpPicURI, 'http')) then $tmpPicURI
            else ()
        let $tmpLinkTarget := $img/parent::xhtml:a/@href
        let $linkTarget := 
            (: Create a link to Wikipedia, e.g. https://de.wikipedia.org/wiki/Datei:Constanze_mozart.jpg :)
            (: NB, not all images are found at wikimedia commons due to copyright issues :)
            switch($lang) 
            case 'de' return functx:substring-before-if-contains(replace($tmpLinkTarget, '.+:', 'https://de.wikipedia.org/wiki/Datei:'), '&amp;')
            default return functx:substring-before-if-contains(replace($tmpLinkTarget, '.+:', 'https://en.wikipedia.org/wiki/File:'), '&amp;')
        (:  Wikimedia IIIF
            siehe https://groups.google.com/forum/?hl=en#!topic/iiif-discuss/UTD181dxKtU
            https://github.com/Toollabs/zoomviewer
        :)
        let $caption :=  
            if($img/ancestor::xhtml:td[@class='infobox-image']) then
        				 $img/ancestor::xhtml:td[@class='infobox-image']//xhtml:div[@class='infobox-caption']
             			 else if($img/ancestor::xhtml:figure[1]/xhtml:figcaption) then 
             			 $img/ancestor::xhtml:figure[1]/xhtml:figcaption
             			 else ()
        return 
            if($thumbURI castable as xs:anyURI) then
                map {
                    'caption' : normalize-space(concat($caption,' (', lang:get-language-string('sourceWikipedia', $lang), ')')),
                    'linkTarget' : $linkTarget,
                    'source' : 'Wikimedia',
                    'url' : function($size) {
                        switch($size)
                        case 'thumb' case 'small' return $thumbURI
                        case 'large' return 
                           let $iiifInfo := er:wikimedia-iiif(functx:substring-after-last($linkTarget, ':'))
                           return
                              try {
                                 (: need to fix the IIIF image id due to some bug(?) in the zoomviewer.toolforge.org service :)
                                 if($iiifInfo('height') gt                                 340) then replace($iiifInfo('@id'), 'cache/', 'fcgi-bin/iipsrv.fcgi/?iiif=cache%2F') || '/full/,340/0/native.jpg'
                                 else replace($iiifInfo('@id'), 'cache/', 'fcgi-bin/iipsrv.fcgi/?iiif=cache%2F') || '/full/full/0/native.jpg'
                              }
                              catch * { $thumbURI }
                        default return 
                           let $iiifInfo := er:wikimedia-iiif(functx:substring-after-last($linkTarget, ':'))
                           return
                              try { $iiifInfo('@id') || '/full/full/0/native.jpg' }
                              catch * { $thumbURI }
                    }
                }
            else ()
};

(:~
 : Helper function for retrieving image metadata from Wikimedia
 :
 : @param $images the image filename(s). Multiple images can be queried at once to reduce calls to the external API
 : @param $lang the language variable (de|en)
 : @return a map with the keys 'caption', 'linkTarget', 'source' and 'url' for every image
 :)
declare function img:wikimedia-api-imageinfo($images as xs:string*, $lang as xs:string) as map(*)* {
    (: see https://www.mediawiki.org/wiki/API:Imageinfo :)
    let $endpoint := "https://commons.wikimedia.org/w/api.php"
    let $defaultParams := "?action=query&amp;format=xml&amp;prop=imageinfo&amp;iiurlheight=52&amp;iiprop=url%7Csize"
    let $titlesParam := "&amp;titles=" || encode-for-uri(string-join(distinct-values($images ! img:prep-wikimedia-image-filenames(.)), '|'))
    let $queryURL := xs:anyURI($endpoint || $defaultParams || $titlesParam)
    
    let $localFilepath := str:join-path-elements(($config:tmp-collection-path, 'wikimediaAPI', util:hash($queryURL, 'md5') || '.xml'))
    let $wikiApiResponse := 
        if(count($images) gt 0) 
        then er:cached-external-request($queryURL, $localFilepath)
        else ()
        
    return
        for $page in $wikiApiResponse//page[not(@missing)]
        let $caption := $page/data(@title)
        let $linkTarget := $page//ii/data(@descriptionurl)
        return 
            map {
                'caption' : normalize-space(concat($caption,' (', lang:get-language-string('sourceWikipedia', $lang), ')')),
                'linkTarget' : $linkTarget,
                'source' : 'Wikimedia',
                'url' : function($size) {
                    let $iiifInfo := er:wikimedia-iiif($page/data(@title))
                    return
                        switch($size)
                        case 'thumb' case 'small' return 
                            $page//ii/data(@thumburl)
                        case 'large' return
                            if($page//ii/@height > 340) then replace($page//ii/data(@thumburl), '/\d+px\-', '/340px-')
                            else $page//ii/data(@url)
                        default return 
                            $page//ii/data(@url)
                }
            }
    
};

(:~
 : Helper function for preparing wikimedia image filenames to work with the wikimedia API
 :)
declare %private function img:prep-wikimedia-image-filenames($img as xs:string) as xs:string? {
    if(contains($img, 'Special:FilePath/')) then img:prep-wikimedia-image-filenames(replace($img, '.*Special:FilePath/', 'File:'))
    else if(contains($img, '?')) then img:prep-wikimedia-image-filenames(substring-before($img, '?'))
    else normalize-space(xmldb:decode-uri($img))
};

(:~
 : Helper function for grabbing images from a portraitindex page
 :
 : @author Peter Stadler 
 : @param 
 : @param $lang the language variable (de|en)
 : @return 
 :)
declare %private function img:portraitindex-images($model as map(*), $lang as xs:string) as map(*)* {
    let $gnd := query:get-gnd($model('doc'))
    let $page := 
        if($gnd) then er:grab-external-resource-via-beacon('portraitindexBeacon', $gnd) 
        (:er:grabExternalResource('portraitindex', $gnd, $lang):)
        else ()
    let $pics := $page//xhtml:div[@class='listItemThumbnail']
    return 
        for $div in $pics
        let $picURI := $div//xhtml:img/data(@src)
        return 
            if($picURI castable as xs:anyURI) then
                map {
                    'caption' : normalize-space($div/following-sibling::xhtml:p/xhtml:a) || ', ' || replace(normalize-space(string-join($div/following-sibling::xhtml:p/text(), ' ')), '&#65533;', ' ') || ' (Quelle: Digitaler Portraitindex)',
                    'linkTarget' : $div/xhtml:a/data(@href),
                    'source' : 'Digitaler Portraitindex',
                    'url' : function($size) {
                        $picURI
                    }
                }
            else ()
};

(:~
 : Helper function for grabbing images from a tripota page
 :
 : @author Peter Stadler 
 : @param 
 : @param $lang the language variable (de|en)
 : @return 
 :)
declare %private function img:tripota-images($model as map(*), $lang as xs:string) as map(*)* {
    let $gnd := query:get-gnd($model('doc'))
    let $page := 
        if($gnd) then er:grab-external-resource-via-beacon('tripotaBeacon', $gnd)
        (:er:grabExternalResource('tripota', $gnd, $lang):)
        else ()
    let $pics := $page//xhtml:td
    return 
        for $div in $pics[not(xhtml:a/xhtml:img/@src='portraits/dummy.jpg')]
        let $picURI := concat('http://www.tripota.uni-trier.de/',  $div//xhtml:img[starts-with(@src, 'portraits')]/data(@src))
        return 
            if($picURI castable as xs:anyURI) then
                map {
                    'caption' : normalize-space(string-join($div/xhtml:br[2]/following-sibling::node(), ' ')) || ' (Quelle: Trierer Porträtdatenbank)',
                    'linkTarget' : 'http://www.tripota.uni-trier.de/' || $div/xhtml:a[1]/data(@href),
                    'source' : 'Trierer Porträtdatenbank',
                    'url' : function($size) {
                        $picURI
                    }
                }
            else ()
};

(:~
 : Helper function for grabbing images from the Münchner Stadtmuseum
 :
 : @author Peter Stadler 
 : @param 
 : @param $lang the language variable (de|en)
 : @return 
 :)
declare %private function img:munich-stadtmuseum-images($model as map(*), $lang as xs:string) as map(*)* {
    let $gnd := query:get-gnd($model('doc'))
    let $page := 
        if($gnd) then er:grab-external-resource-via-beacon('munich-stadtmuseumBeacon', $gnd)
        (:er:grabExternalResource('munich-stadtmuseum', $gnd, $lang):)
        else ()
    let $pics := $page//xhtml:a[@class='imagelink'][ancestor::xhtml:div[@id='main']]
    return 
        for $a in $pics
        let $picURI := concat('https://stadtmuseum.bayerische-landesbibliothek-online.de', $a/xhtml:img/@src)
        return 
            if($picURI castable as xs:anyURI) then
                map {
                    'caption' : str:normalize-space($a/xhtml:img/@title) || ' (Quelle: Münchner Stadtmuseum)',
                    'linkTarget' : 'https://stadtmuseum.bayerische-landesbibliothek-online.de/pnd/' || $gnd,
                    'source' : 'Münchner Stadtmuseum',
                    'url' : function($size) {
                        $picURI
                    }
                }
            else ()
};

(:~
 : Helper function for grabbing images from the "Bildindex der Kunst und Architektur" (Bildarchiv Foto Marburg) 
 :
 : @author Peter Stadler 
 : @param 
 : @param $lang the language variable (de|en)
 : @return 
 :)
declare %private function img:bildindex-images($model as map(*), $lang as xs:string) as map(*)* {
    let $gnd := query:get-gnd($model('doc'))
    let $url := config:get-option('bildindex') || $gnd
    let $page :=
        (: regrettably we can't cache the request because the bildindex page is creating fast-vanishing image links on the fly :)
        if($gnd) then er:http-get($url)//er:response
        else ()
    let $divs := $page//xhtml:div[contains(@class, 'ssy_galleryElement')]
    return 
        for $div in $divs
        let $picURI := $div/xhtml:figure/xhtml:a/xhtml:img/@edp-src
        return 
            if($picURI castable as xs:anyURI) then
                map {
                    'caption' : str:normalize-space($div//xhtml:span[contains(@class, 'galHeadline')]) || ' (Quelle: Bildindex der Kunst und Architektur)',
                    'linkTarget' : $div/xhtml:figure/xhtml:a/data(@href),
                    'source' : 'Bildindex der Kunst und Architektur',
                    'url' : function($size) {
                        if($picURI = '/images/nopic_large.png')
                    then ()
                        else $picURI
                    }
                }
            else ()
};

(:~
 : Helper function for adding local (= from the WeGA) images
 :
 : @author Peter Stadler 
 : @param 
 : @param $lang the language variable (de|en)
 : @return 
 :)
declare %private function img:wega-images($model as map(*), $lang as xs:string) as map(*)* {
    let $iiifImageApi := config:get-option('iiifImageApi')
    return
        for $fig in core:getOrCreateColl('iconography', $model('docID'), true())//tei:figure[tei:graphic]
        let $docType := 
            if($fig/tei:figDesc/tei:listPlace) then 'places'
            else if($fig/tei:figDesc/tei:listOrg) then 'orgs'
            else 'persons'
        let $iiifURI := $iiifImageApi || encode-for-uri(string-join(($docType, substring($model('docID'), 1, 5) || 'xx', $model('docID'), $fig/tei:graphic/@url), '/'))
        order by $fig/@n (: markup with <figure n="portrait"> takes precedence  :)
        return 
            map {
                'caption' : normalize-space($fig/preceding::tei:title),
                'linkTarget' : $iiifURI || '/full/full/0/native.jpg',
                'source' : wega-util:transform($fig//tei:bibl, doc(concat($config:xsl-collection-path, '/persons.xsl')), config:get-xsl-params(())),
                'url' : function($size) {
                    switch($size)
                    case 'thumb' return $iiifURI || '/full/,52/0/native.jpg'
                    case 'small' return $iiifURI || '/full/,60/0/native.jpg'
                    case 'large' return $iiifURI || '/full/,340/0/native.jpg'
                    default return $iiifURI || '/full/full/0/native.jpg'
                }
            }
};

declare 
    %templates:default("lang", "en")
    function img:portrait($node as node(), $model as map(*), $lang as xs:string, $size as xs:string) as element() {
        if(exists($model?portrait)) then 
            let $url := $model('portrait')('url')($size)
            return
                element {node-name($node)} {
                    $node/@*[not(local-name(.) = ('src', 'title', 'alt'))],
                    if($model('portrait')('caption')) then (
                        attribute title {$model('portrait')('caption')},
                    attribute alt {$model('portrait')('caption')}
                    )
                    else attribute alt {'Preview Icon'},
                    attribute src {$url}
                }
        else $node
};

declare %private function img:get-generic-portrait($model as map(*), $lang as xs:string) as map(*) {
    let $sex := 
        if(config:is-org($model('docID'))) then 'org'
        else if(config:is-place($model('docID'))) then 'place'
        else if($model('doc')//mei:term/data(@class) = 'http://d-nb.info/standards/elementset/gnd#MusicalWork') then 'musicalWork'
        else if(config:is-work($model('docID')) and hwh-util:get-work-type($model('docID')) = 'music') then 'musicalWork'
        else if(config:is-work($model('docID')) and hwh-util:get-work-type($model('docID')) = 'tape') then 'tape'
        else if(config:is-work($model('docID')) and hwh-util:get-work-type($model('docID')) = 'cd') then 'compactDisc'
        else if(config:is-work($model('docID')) and hwh-util:get-work-type($model('docID')) = 'film') then 'film'
        else if(config:is-work($model('docID')) and hwh-util:get-work-type($model('docID')) = 'lp') then 'longPlay'
        else if(config:is-work($model('docID')) and $model('doc')//tei:biblStruct[@type='painting']) then 'painting'
        else if(config:is-work($model('docID'))) then 'otherWork'
        else if(config:is-corresp($model('docID'))) then 'corresp'
        else if(config:is-biblio($model('docID'))) then 'biblio'
        else $model('doc')//tei:sex/text()
     let $caption :=
        if(config:is-person($model('docID')))
        then 'no portrait available'
        else ()
    return
        map {
            'caption' : $caption,
            'linkTarget' : (),
            'source' : 'Carl-Maria-von-Weber-Gesamtausgabe',
            'url' : function($size) {
                switch($size)
                case 'thumb' case 'small' return 
                    switch($sex)
                    case 'f' return config:link-to-current-app('resources/img/icons/icon_person_female.svg')
                    case 'm' return config:link-to-current-app('resources/img/icons/icon_person_male.svg')
                    case 'org' return config:link-to-current-app('resources/img/icons/icon_orgs.png')
                    case 'place' return config:link-to-current-app('resources/img/icons/icon_places.png')
                    case 'musicalWork' return config:link-to-current-app('resources/img/icons/icon_musicalWork.svg')
                    case 'tape' return config:link-to-current-app('resources/img/icons/icon_tape.svg')
                    case 'film' return config:link-to-current-app('resources/img/icons/icon_film.svg')
                    case 'longPlay' return config:link-to-current-app('resources/img/icons/icon_vinyl.svg')
                    case 'compactDisc' return config:link-to-current-app('resources/img/icons/icon_compactDisc.svg')
                    case 'otherWork' case 'biblio' return config:link-to-current-app('resources/img/icons/icon_biblio.svg')
                    case 'corresp' return config:link-to-current-app('resources/img/icons/icon_corresp.svg')
                    case 'painting' return config:link-to-current-app('resources/img/icons/icon_painting.svg')
                    default return config:link-to-current-app('resources/img/icons/icon_person.svg')
                default return 
                    switch($sex)
                    case 'f' return config:link-to-current-app('resources/img/icons/icon_person_female.svg')
                    case 'm' return config:link-to-current-app('resources/img/icons/icon_person_male.svg')
                    case 'org' return config:link-to-current-app('resources/img/icons/icon_orgs_gross.png')
                    case 'place' return config:link-to-current-app('resources/img/icons/icon_places_gross.png')
                    case 'musicalWork' return config:link-to-current-app('resources/img/icons/icon_musicalWork.svg')
                    case 'tape' return config:link-to-current-app('resources/img/icons/icon_tape.svg')
                    case 'film' return config:link-to-current-app('resources/img/icons/icon_film.svg')
                    case 'longPlay' return config:link-to-current-app('resources/img/icons/icon_vinyl.svg')
                    case 'compactDisc' return config:link-to-current-app('resources/img/icons/icon_compactDisc.svg')
                    case 'otherWork' case 'biblio' return config:link-to-current-app('resources/img/icons/icon_biblio.svg')
                    case 'painting' return config:link-to-current-app('resources/img/icons/icon_painting.svg')
                    case 'corresp' return config:link-to-current-app('resources/img/icons/icon_corresp.svg')
                    default return config:link-to-current-app('resources/img/icons/icon_person.svg')
            }
        }
};

(:~
 : Create an IIIF collection for a WeGA document type collection
 : WARNING: This is considered experimental beacuse it spits out too many manifests and the services choke on it 
 :
 : @param $docType the WeGA docType, e.g. 'letters' or 'writings'
 : @return a collection object
 :)
declare function img:iiif-collection($docType as xs:string) as map(*) {
    map {
        "@context" : "http://iiif.io/api/presentation/2/context.json",
        "@id" : "https://weber-gesamtausgabe.de/IIIF/letters",
        "@type" : "sc:Collection",
        "label" : "Top Level Letters Collection for the Carl-Maria-von-Weber-Gesamtausgabe",
        "viewingHint" : "top",
        "description" : "Description of Collection kommt später",
        "attribution" : "Provided by the WeGA",
        "manifests" : array {
            core:getOrCreateColl($docType, 'indices', true())//tei:facsimile ! map {
                "@id": controller:iiif-manifest-id(.),
                "@type": "sc:Manifest",
                "label": ./ancestor::tei:TEI/@xml:id || ./@source
            }
        }
    }
};

(:~
 : Create an IIIF manifest for a TEI facsimile element
 :
 : @param $facsimile a TEI facsimile element
 : @return a manifest object
 :)
declare function img:iiif-manifest($facsimile as element(tei:facsimile)) as map(*) {
    let $iiifImageApi := config:get-option('iiifImageApi')
    let $docID := $facsimile/ancestor::tei:TEI/@xml:id
    let $manifest-id := controller:iiif-manifest-id($facsimile)
    let $label := $docID || $facsimile/@source
    let $desc := wdt:lookup(config:get-doctype-by-id($docID), $docID)('title')('txt')
    let $attribution := img:iiif-manifest-attribution($facsimile)
    return
        map {
            "@context" : "http://iiif.io/api/presentation/2/context.json",
            "@id" : $manifest-id,
            "@type" : "sc:Manifest", 
            "label" : $label,
            "description" : $desc,
            "attribution" : $attribution,
            "license" : query:licence($facsimile/root()),
            "logo" : map {
                "@id" : "https://weber-gesamtausgabe.de/resources/img/logo_weber.png",
                "service" : map {
                    "@context" : "http://iiif.io/api/image/2/context.json",
                    "@id" : "https://weber-gesamtausgabe.de/resources/img/logo_weber.png",
                    "profile" : "http://iiif.io/api/image/2/level2.json"
                }
            },
            "sequences" : [ map {
                "@context" : "http://iiif.io/api/presentation/2/context.json",
                "@id" : replace($manifest-id, 'manifest.json', 'sequence/') || 'default',
                "@type" : "sc:Sequence", 
                "label" : "default",
                "viewingHint" : "paged",
                "canvases" : array {
                    $facsimile/tei:graphic ! img:iiif-canvas(.)
                }
            }]
        }
};

(:~
 : Create an IIIF canvas for a TEI graphic element
 : There are three supported ways to provide image resources:
 : * via url-attribute and providing a file name (WeGA folder structure conventions are assumed): `<graphic url="1815-09-16_AM_Weber_an_GottfriedW_US-NHub_1v.tif" xml:id="facs_1v"/>`
 : * via sameAs-attribute, pointing at an online IIIF resource: `<graphic sameAs="https://api.digitale-sammlungen.de/iiif/image/v2/bsb10527978_00173"/>`
 : * via sameAs-attribute, using the wega-prefix notation: `<graphic sameAs="wega:/letters/A0475xx/A047515/A047515_03.jpg"/>`
 :
 : @param $graphic a TEI graphic element
 : @return a canvas object
 :)
declare function img:iiif-canvas($graphic as element(tei:graphic)) as map(*) {
    let $image-id as xs:anyURI? :=
        if(starts-with($graphic/@sameAs, 'wega:')) then xs:anyURI(config:get-option('iiifImageApi') || encode-for-uri(substring-after($graphic/@sameAs, 'wega:')))
        else if($graphic/@sameAs) then xs:anyURI($graphic/@sameAs)
        else if($graphic/@url) then img:relative-WeGA-image-path2iiif-image-id($graphic)
        else ()
    let $page-label := 
        if($graphic/@xml:id) then $graphic/string(@xml:id)
        else 'page' || count($graphic/preceding::tei:graphic) + 1
    let $manifest-id := controller:iiif-manifest-id($graphic/parent::tei:facsimile)
    let $canvas-id := replace($manifest-id, 'manifest.json', 'canvas/') || encode-for-uri($page-label)
    let $image-info :=
        try {
            er:http-get(xs:anyURI($image-id || '/info.json'))//*:response => util:base64-decode() => parse-json() (: why is this not cached? – the wrapper request to the manifest.json is cached! :)
        }
        catch * {
            wega-util:log-to-file('error', 'failed to fetch image info for ' || $image-id)
        }
    return 
        map:merge((
            map:entry("@context", "http://iiif.io/api/presentation/2/context.json"),
            map:entry("@id", $canvas-id),
            map:entry("@type", "sc:Canvas"),
            map:entry("label", $page-label),
            map:entry("height", xs:integer($image-info?height)),
            map:entry("width", xs:integer($image-info?width)),
            map:entry("images", [ img:iiif-image( map { 
                "image-id" : $image-id,
                "canvas-id" : $canvas-id,
                "manifest-id" : $manifest-id,
                "height" : xs:integer($image-info?height),
                "width" : xs:integer($image-info?width)
            } ) ])
        ))
};

(:~
 : Create an IIIF image object
 :
 : @param 
 : @return a image object
 :)
declare %private function img:iiif-image($model as map(*)) as map(*) {
    map {
        "@type" : "oa:Annotation",
        "@id" : $model?image-id || '/annotation', 
        "motivation" : "sc:painting",
        "on" : $model?canvas-id,
        "resource" : map {
            "@id" : $model?image-id || "/full/400,/0/default.jpg",
            "@type" : "dctypes:Image",
            "height" : $model?height,
            "width" : $model?width,
            "format" : "image/jpg",
            "service" : map {
                "@context" : "http://iiif.io/api/image/2/context.json", 
                "@id" : $model?image-id, 
                "profile" : "http://iiif.io/api/image/2/level2.json"
            }
        }
    }
};

(:~
 : Get human readable image attribution information for a digital facsimile 
 : Helper function for img:iiif-manifest()
 :
 : @param $facsimile a TEI facsimile element
 : @return a human readable string referring to the image source
 :)
declare %private function img:iiif-manifest-attribution($facsimile as element(tei:facsimile)) as xs:string {
    let $source := query:facsimile-witness($facsimile)
    return
        typeswitch($source)
        case element(tei:msDesc) return str:normalize-space($source/tei:msIdentifier/tei:repository)
        case element(tei:msFrag) return str:normalize-space($source/tei:msIdentifier/tei:repository)
        case element(tei:biblStruct) return str:normalize-space($source/tei:monogr/tei:title[1])
        case element(tei:bibl) return str:normalize-space($source)
        default return 'Carl-Maria-von-Weber-Gesamtausgabe'
};

(:~
 : Turn relative image paths into proper IIIF image IDs
 : Helper function for img:iiif-canvas()
 :
 : @param $graphic a TEI graphic element (within a tei:facsimile element)
 : @return the proper IIIF URL to address this image resource
 :)
declare %private function img:relative-WeGA-image-path2iiif-image-id($graphic as element(tei:graphic)) as xs:anyURI {
    let $docID := $graphic/ancestor::tei:TEI/@xml:id
    let $iiifImageApi := config:get-option('iiifImageApi')
    let $db-path := substring-after(config:getCollectionPath($docID), $config:data-collection-path || '/')
    return
        xs:anyURI($iiifImageApi || encode-for-uri(str:join-path-elements(($db-path, $docID, $graphic/@url))))
};
