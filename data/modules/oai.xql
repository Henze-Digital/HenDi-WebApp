xquery version "3.1" encoding "UTF-8";

(:~
 :
 :  Module for exporting BEACON files
 :  see https://de.wikipedia.org/wiki/Wikipedia:BEACON
 :
 :)

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace oai="http://www.openarchives.org/OAI/2.0/";

import module namespace functx="http://www.functx.com";
import module namespace crud="http://xquery.weber-gesamtausgabe.de/modules/crud" at "crud.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/date.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";
import module namespace mycache="http://xquery.weber-gesamtausgabe.de/modules/cache" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/cache.xqm";
import module namespace lod="http://xquery.weber-gesamtausgabe.de/modules/lod" at "lod.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "wdt.xqm";

declare option output:method "xml";
declare option output:media-type "application/xml";
declare option output:indent "yes";

declare variable $oai:last-modified as xs:dateTime? := 
    if($config:svn-change-history-file/dictionary/@dateTime castable as xs:dateTime) 
    then $config:svn-change-history-file/dictionary/xs:dateTime(@dateTime)
    else (
        let $versionDateSeq := tokenize(config:get-option('versionDate'),'-')
        let $year := subsequence($versionDateSeq,1,1)
        let $month := subsequence($versionDateSeq,2,1)
        let $day := subsequence($versionDateSeq,3,1)
        return
            functx:dateTime($year,$month,$day,0,0,0)
    );

declare variable $oai:lang as xs:string := config:guess-language(());

declare %private function oai:response-headers() as empty-sequence() {
    response:set-header('Access-Control-Allow-Origin', '*'),
    response:set-header('Last-Modified', date:rfc822($oai:last-modified)), 
    response:set-header('Cache-Control', 'max-age=300,public')
};

declare function oai:DC.description($id as xs:string?, $oai:lang as xs:string) as xs:string? {
    let $docType := 'person'
    let $doc := crud:doc($id)
    let $orgTypes := for $each in $doc//tei:state[@type='orgType']/tei:desc/tei:term
                        return
                            lang:get-language-string(concat('orgType.',$each/text()), $oai:lang)
    return
    
    switch($id)
    case 'indices' return lang:get-language-string('metaDescriptionIndex-' || $docType, $oai:lang)
    case 'home' return lang:get-language-string('metaDescriptionIndex', $oai:lang)
    case 'search' return lang:get-language-string('metaDescriptionSearch', $oai:lang)
    default return
        switch($docType)
        case 'persons' return 
            let $dates := concat(date:printDate($doc//tei:birth/tei:date[1],$oai:lang,lang:get-language-string#3, $config:default-date-picture-string), '–', date:printDate($doc//tei:death/tei:date[1],$oai:lang,lang:get-language-string#3, $config:default-date-picture-string))
            let $occupations := string-join($doc//tei:occupation/normalize-space(), ', ')
            let $placesOfAction := string-join($doc//tei:residence/normalize-space(), ', ')
            return concat(
                lang:get-language-string('bioInfoAbout', $oai:lang), ' ', 
                str:print-forename-surname(query:title($id)),'. ',
                lang:get-language-string('pnd_dates', $oai:lang), ': ', 
                $dates, '. ',
                lang:get-language-string('occupations', $oai:lang), ': ',
                $occupations, '. ',
                lang:get-language-string('placesOfAction', $oai:lang), ': ', 
                $placesOfAction
            )
        case 'letters' case 'writings' case 'documents' return str:normalize-space($doc//tei:note[@type='summary'])
        case 'diaries' return str:shorten-TEI($doc/tei:ab, 150, $oai:lang)
        case 'news' case 'var' case 'thematicCommentaries' return str:shorten-TEI($doc//tei:text//tei:p[not(starts-with(., 'Sorry'))], 150, $oai:lang)
        case 'orgs' return wdt:orgs($doc)('title')('txt') || ': ' || str:list($orgTypes, $oai:lang, 0, lang:get-language-string#2)
        case 'corresp' return lang:get-language-string('corresp', $oai:lang)
        case 'biblio' return lang:get-language-string('biblio', $oai:lang)
        case 'places' return lang:get-language-string('place', $oai:lang)
        case 'works' return lang:get-language-string('workName', $oai:lang)
        case 'addenda' return lang:get-language-string($docType, $oai:lang)
        case 'error' return lang:get-language-string('metaDescriptionError', $oai:lang)
        default return wega-util:log-to-file('warn', 'Missing HTML meta description for ' || $id || ' – ' || $docType || ' – ' || request:get-uri())
};

declare function oai:oai($id as xs:string) as node() {
	<OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd">
		 <responseDate>{fn:current-dateTime()}</responseDate>
		 <request verb="GetRecord" identifier="https://henze-digital.zenmem.de/de/{$id}" metadataPrefix="oai_dc">http://www.openarchives.org/OAI/2.0/oai_dc/</request> 
		 <GetRecord>
			  {oai:record($id)}
		 </GetRecord> 
	</OAI-PMH>      
};

declare function oai:record($id as xs:string) as node() {
	<record xmlns="http://www.openarchives.org/OAI/2.0/">
    	<header>
          <identifier>https://henze-digital.zenmem.de/de/{$id}</identifier>
          <datestamp>{fn:current-dateTime()}</datestamp>
          <setSpec>DOCTYPE</setSpec>
        </header>
        <metadata>
         <oai_dc:dc 
             xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" 
             xmlns:dc="http://purl.org/dc/elements/1.1/" 
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
             xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ 
             http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
           <dc:title>TITLE OF THE RECORD/PAGE</dc:title>
           <dc:creator>SURNAME, FORENAME</dc:creator>
           <dc:subject>SUBJECT</dc:subject>
           <dc:description>{oai:DC.description($id, $oai:lang)}</dc:description>
           <dc:date>{substring($oai:last-modified,1,10)}</dc:date>
           <dc:identifier>{$id}</dc:identifier>
         </oai_dc:dc>
        </metadata>
        <about> 
          <provenance
              xmlns="http://www.openarchives.org/OAI/2.0/provenance" 
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
              xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/provenance
              http://www.openarchives.org/OAI/2.0/provenance.xsd">
            <originDescription harvestDate="{fn:current-dateTime()}" altered="true">
              <baseURL>https://henze-digital.zenmem.de</baseURL>
              <identifier>{$id}</identifier>
              <datestamp>{substring($oai:last-modified,1,10)}</datestamp>
              <metadataNamespace>http://www.openarchives.org/OAI/2.0/oai_dc/</metadataNamespace>
            </originDescription>
          </provenance>
        </about>
	</record>      
};

let $docID := request:get-attribute('docID')
return
    (
        oai:response-headers(),
        response:set-status-code(202),
        oai:oai($docID)
    )