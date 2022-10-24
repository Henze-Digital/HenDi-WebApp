xquery version "3.1";

module namespace hwh-util="http://henze-digital.zenmem.de/modules/hwh-util";

import module namespace functx="http://www.functx.com";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";


(:~
 : compute check digit
 : @param $id the id for which the check digit should be computed 
 :)
declare function hwh-util:compute-check-digit($id as xs:string) as xs:string {
    let $weights := (2, 4, 6, 8, 9, 5, 3)
    let $weighted-codepoints := for $i at $c in string-to-codepoints($id) return $i * $weights[$c]
    let $sum := sum($weighted-codepoints)
    return
        hwh-util:int2hex(xs:int($sum mod 16))
};

(:~
 : convert an integer into a hex string
 : @param $number number to convert
 :)

declare function hwh-util:int2hex($number as xs:int) as xs:string {
    let $chars := ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F')
    let $div := $number div 16
    let $count := floor($div)
    let $remainder := ($div - $count) * 16
    return
        concat(
            if($count gt 15) 
            then hwh-util:int2hex(xs:integer($count))
            else if($number gt 15) then $chars[$count +1]
            else (),
            $chars[$remainder +1]
        )
};

(:~
 : convert a hex string into an integer
 : @see http://blog.sam.liddicott.com/2006/04/xslt-hex-to-decimal-conversion.html
 : @param $str ID (sub)string
:)
declare function hwh-util:hex2int($str as xs:string) as xs:integer? {
    if($str) then (
        let $len := fn:string-length($str)
        return
            if ( $len lt 2 ) 
            then string-length(substring-before('0 1 2 3 4 5 6 7 8 9 AaBbCcDdEeFf', $str)) idiv 2
            else hwh-util:hex2int(substring($str, 1, $len - 1))*16 + hwh-util:hex2int(substring($str,$len))
    )
    else ()
};

(:~
 : Generate an ID for henze-digital
 : @author  Dennis Ried
 : @param   $prefix the id-prefix (like 'A00'). special concern of Henze-Digital
 : @param   $i next floating number from ID-list
:)
declare function hwh-util:generateId($prefix as xs:string, $i as xs:int) as xs:string {
    let $idSubStr := functx:reverse-string(
                        functx:pad-string-to-length(
                            functx:reverse-string(
                                hwh-util:int2hex($i)
                            ), '0', 4
                        )
                     ) 
    let $prefixedIdSubStr := concat($prefix, $idSubStr)
    let $checkDigit := hwh-util:compute-check-digit($prefixedIdSubStr)
    return
        concat($prefixedIdSubStr, $checkDigit)
};

(:~
 : @author  Nikolaos Beer
 : @see     https://reger-werkausgabe.de 
 : @param   $args the element(s) that should be checked
 : @param   $searchStrings value(s) against the check is executed
:)
declare function hwh-util:any-equals-any($args as xs:string*, $searchStrings as xs:string*) as xs:boolean {
  some $arg in $args
  satisfies
    some $searchString in $searchStrings
    satisfies
      $arg = $searchString
};

(:~
 : @author  Dennis Ried
 : @param   $results a sequence of nodes to be iterated and ordered
 : @param   $sortParam (optional) a node that should be used for ordering
:)
declare function hwh-util:iterateResults($results as node()*, $sortParam as node()?) as node()* {
    for $result in $results
        let $sort := if($sortParam) then($sortParam) else($result)
        order by $sort
        return
            $result
}; 
