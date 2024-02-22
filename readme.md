# Shahed Utils

## Food



## Behestan

### TODO
reconsider every little `a` becuase it is either `g` or `q`

###
[character segmentation of captcha image :: stackoverflow](https://stackoverflow.com/questions/24150431/character-segmentation-of-captcha-image)

https://stackoverflow.com/questions/33294595/segmenting-letters-in-a-captcha-image?rq=3


### Data
```
Get-ChildItem -Filter *.gif | Remove-Item
```
```
magick.exe mogrify -format png *.gif
```

convert to black & white
```
magick mogrify -alpha off -auto-threshold otsu *.png
```

```
magick mogrify -crop 140x44+0+0 *.png
```

thanks to https://stackoverflow.com/questions/65945662/how-do-i-convert-a-color-image-to-black-and-white-using-imagemagick


https://github.com/pythonlessons/mltu/tree/main/Tutorials/02_captcha_to_text

### Methodology
1. export all the HTTP requests as `.har` file from `FireFox`
2. clean it by `./scripts/har.nim`
3. simulate by `./scripts/sim.nim`

#### Autentication and access control
it is based on `ticket`, which means API calls are sequential.

the order or API calls matters. if you miss one, ot wont work...

the first ticket is given to you after you have logged in successfully.
each API take a `ticket` and return 1 or 2 `ticket`s. 
you use the given tickets for future API calls.

produced by `./scripts/tck_tracer.nim`: (`--` means taken, `++` means given)
```
--------------------------------------- #0 -----
frm/loginapi/loginapi.svc/
-- 1
++ $TCK_1  aut.tck
--------------------------------------- #1 -----
frm/nav/nav.svc/
-- $TCK_1
++ $TCK_2  aut.tck
++ $TCK_4  oaut.oa.nmtck
--------------------------------------- #2 -----
frm/F0213_PROCESS_SYSMENU0/F0213_PROCESS_SYSMENU0.svc/
-- $TCK_2
++ $TCK_3  aut.tck
++ $TCK_3  oaut.oa.nmtck
--------------------------------------- #3 -----
frm/nav/nav.svc/
-- $TCK_4
++ $TCK_5  aut.tck
++ $TCK_8  oaut.oa.nmtck
--------------------------------------- #4 -----
frm/BAS0274_UserFavorate_Show_Beh/BAS0274_UserFavorate_Show_Beh.svc/
-- $TCK_5
++ $TCK_6  aut.tck
--------------------------------------- #5 -----
frm/Edu0203_Desktop_BEH/Edu0203_Desktop_BEH.svc/
-- $TCK_6
++ $TCK_7  aut.tck
--------------------------------------- #6 -----
frm/nav/nav.svc/
-- $TCK_8
++ $TCK_10  aut.tck
++ $TCK_13  oaut.oa.nmtck
--------------------------------------- #7 -----
frm/F6524_PROCESS_DASHBOARD_BEH/F6524_PROCESS_DASHBOARD_BEH.svc/
-- $TCK_10
++ $TCK_11  aut.tck
--------------------------------------- #8 -----
frm/F6524_PROCESS_DASHBOARD_BEH/F6524_PROCESS_DASHBOARD_BEH.svc/
-- $TCK_11
++ $TCK_12  aut.tck
--------------------------------------- #9 -----
frm/nav/nav.svc/
-- $TCK_13
++ $TCK_14  aut.tck
++ $TCK_??  oaut.oa.nmtck
--------------------------------------- #10 -----
frm/Edu0301_Terms_TrmNo_Lookup/Edu0301_Terms_TrmNo_Lookup.svc/
-- $TCK_14
++ $TCK_15  aut.tck
--------------------------------------- #11 -----
frm/Edu1002_UnvFac_FacNo_Lookup/Edu1002_UnvFac_FacNo_Lookup.svc/
-- $TCK_15
++ $TCK_16  aut.tck
--------------------------------------- #12 -----
frm/Edu1021_UNVBRANCHES_Brnno_Lookup/Edu1021_UNVBRANCHES_Brnno_Lookup.svc/
-- $TCK_16
++ $TCK_17  aut.tck
--------------------------------------- #13 -----
frm/nav/nav.svc/
-- $TCK_17
++ $TCK_18  aut.tck
++ $TCK_19  oaut.oa.nmtck
--------------------------------------- #14 -----
frm/F1825_PROCESS_STDTOTALINFO_BEH/F1825_PROCESS_STDTOTALINFO_BEH.svc/
-- $TCK_19
++ $TCK_19  aut.tck
--------------------------------------- #15 -----
frm/F1825_PROCESS_STDTOTALINFO_BEH/F1825_PROCESS_STDTOTALINFO_BEH.svc/
-- $TCK_19
++ $TCK_20  aut.tck
--------------------------------------- #16 -----
frm/F1809_PROCESS_STD_Personally_BH/F1809_PROCESS_STD_Personally_BH.svc/
-- $TCK_18
++ $TCK_21  aut.tck
--------------------------------------- #17 -----
frm/F1825_PROCESS_STDTOTALINFOTrmStat_BEH/F1825_PROCESS_STDTOTALINFOTrmStat_BEH.svc/
-- $TCK_20
++ $TCK_22  aut.tck
```

### Fun facts

#### security

##### the Captcha which is sent as `gif` is actually `jpeg`!!

##### the captcha is not unique for users and it remains the same for about 2-10 mins

##### One of the http headers after you log in:
```
Authorization = Bearer [object Object]
```

#### Overall Design
##### JSON/XML nesting
some APIs are just ... messy
```json
"grd": [
  {
    "struc": "<< serialized JSON that you have to parse it... >>",

    "xml": "<grd id=\"AUWr\" ><dat><row F1=\"انتقال داده ها\" F2=\"1712099 گروه 01\"  F18=\"[{&quot;Ftype&quot;:&quot;0&quot;,&quot;Fid&quot;:15390,&quot;PARAM&quot;:&quot;[{\\&quot;Title\\&quot;:\\&quot;رسيدگي به اعتراض\\&quot;,\\&quot;ScrOpenParam\\&quot;:\\&quot;&lt;row FTYPE=\\\\\\&quot;0\\\\\\&quot; FID=\\\\\\&quot;15390\\\\\\&quot;&gt;&lt;Parm&gt;&lt;row STDNO=\\\\\\&quot;$STD_NUMBER\\\\\\&quot; TRMNO=\\\\\\&quot;4021\\\\\\&quot; CFACNO=\\\\\\&quot;17\\\\\\&quot; CGRPNO=\\\\\\&quot;12\\\\\\&quot; CRSNO=\\\\\\&quot;099\\\\\\&quot; CBRNNO=\\\\\\&quot;0\\\\\\&quot; GRP=\\\\\\&quot;01\\\\\\&quot; \\\\\\/&gt;&lt;\\\\\\/Parm&gt;&lt;\\\\\\/row&gt;\\&quot;}]&quot;}]\" F19=\"\" F20=\"\" F21=\"\"/>
  }
]
```

you have to extract the `xml` field and clean the XML data: ...
```xml
<row 
F1="انتقال داده ها"
F2="1712099 گروه 01"
F18= "[{'Ftype':'0','Fid':15390,'PARAM':'[{'Title':'رسيدگي به اعتراض','ScrOpenParam':'<row FTYPE='0' FID='15390'><Parm><row STDNO='$STD_NUMBER' TRMNO='4021' CFACNO='17' CGRPNO='12' CRSNO='099' CBRNNO='0' GRP='01'/></Parm></row>'}]'}]"
/>
```

then the value inside attribute `F18` is JSON:
```json
[{
  "Ftype":"0",
  "Fid":15390,
  "PARAM": [
    {
      "Title":"رسيدگي به اعتراض",
      "ScrOpenParam": "<row FTYPE='0' FID='15390'><Parm><row STDNO='$STD_NUMBER' TRMNO='4021' CFACNO='17' CGRPNO='12' CRSNO='099' CBRNNO='0' GRP='01'/></Parm></row>'}]"
    }
  ]
```

then again the value for `ScrOpenParam` is XML:
```xml
<row FTYPE='0' FID='15390'>
  <Parm>
    <row 
      STDNO='$STD_NUMBER' 
      TRMNO='4021' 
      CFACNO='17' 
      CGRPNO='12' 
      CRSNO='099' 
      CBRNNO='0'
      GRP='01'/>
  </Parm>
</row>
```

##### API URLs
take 
https://eduportal.shahed.ac.ir/frm/SBS1201_CODES_LOOKUP_DSC/SBS1201_CODES_LOOKUP_DSC.svc/%7B$6r$6$1%7B$6MaxHlp$6$1$610000$6,$6RWM$6$1$6SYS$6,$6_LkId$6$1$6$6,$6AYPY$6$1$61$6%7D,$6act$6$1$620$6%7D for example. 

the last part of url is:
```
%7B$6r$6$1%7B$6MaxHlp$6$1$610000$6,$6RWM$6$1$6SYS$6,$6_LkId$6$1$6$6,$6AYPY$6$1$61$6%7D,$6act$6$1$620$6%7D
```

if we "url decode" it:
```
/{$6r$6$1{$6MaxHlp$6$1$610000$6,$6RWM$6$1$6LVL$6,$6_LkId$6$1$610$6,$6ySF$6$1$610$6,$6AYPX$6$1$610$6,$6AYPY$6$1$61$6},$6act$6$1$620$6}
```

replace `$6` with `"` and `$1` with `:`
```json
{"r":{"MaxHlp":"10000","RWM":"LVL","_LkId":"10","ySF":"10","AYPX":"10","AYPY":"1"},"act":"20"}
```

pretty form:
```json
{
  "r": {
    "MaxHlp": "10000",
    "RWM": "LVL",
    "_LkId": "10",
    "ySF": "10",
    "AYPX": "10",
    "AYPY": "1"
  },
  "act": "20"
}
```

#### Other

##### Translations
API: https://eduportal.shahed.ac.ir/frm/SBS1201_CODES_LOOKUP_DSC/SBS1201_CODES_LOOKUP_DSC.svc/%7B$6r$6$1%7B$6MaxHlp$6$1$610000$6,$6RWM$6$1$6SYS$6,$6_LkId$6$1$6$6,$6AYPY$6$1$61$6%7D,$6act$6$1$620$6%7D
```xml
<row C1="1" C2="روزانه" C3="Daily" C4="1"/>
<row C1="5" C2="شبانه" C3="Nightly" C4="1"/>
<row C1="10" C2="آموزشهاي آزاد" C3="Free Education" C4="2"/> <!-- "Free" does not mean this here ... -->
<row C1="15" C2="نوبت دوم" C3="Second Chance" C4="1"/> <!-- I'm sure the word "chance" has different meaning... -->
<row C1="20" C2="شهريه پرداز" C4="3"/> <!-- sorry it does not have translation :D -->
<row C1="25" C2="نيمه حضوري" C3="Half" C4="4"/> <!-- half of what?? -->
<row C1="30" C2="پودماني" C3="Poodemani" C4="5"/> <!-- Finglish? Really?? -->
<row C1="35" C2="قالب پرديس" C3="Pardis" C4="6"/>
```

##### Typos
one of the APIs is `BAS0274_UserFavorate_Show_Beh` which `Favorate` should be `favorite` AFAIK
