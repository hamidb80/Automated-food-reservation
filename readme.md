# Shahed Utils

## Food

## Behestan

### Methodology
1. export all the HTTP requests as `.har` file from `FireFox`
2. clean it by `./scripts/har.nim`
3. simulate by `./scripts/sim.nim`
4. `./scripts/tck_tracer.nim` helped


### Fun facts
#### One of the http headers after you log in:
```
Authorization = Bearer [object Object]
```

#### Translations
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

### API URLs
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

replace `$6` with `"` and $1 with `:`:
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

#### Typos
one of the APIs is `BAS0274_UserFavorate_Show_Beh` which `Favorate` should be `favorite` AFAIK

#### JSON/XML nesting
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

#### Autentication and access control
it is based on `ticket` and API calls are sequential

### API terminologies
- `tck`: ticket
- `nmtck`: new module/mode ticket
- `nurlp`: new/next url path
- `nurlf`: new/next url form/function
- `std`: student
- `lvl`: level
- `frm`: form
- `usr`: user
- `nam`: name
- `fam`: family [last name]
- `usrnam`: user name [first name]
- `usrfam`: user family [last name]
- `aut`: authentication
- `oaut`: open authentication/access
- `oa`: open access
- `_ret`: return
- `val`: value
- `dsc`: descrption
- `sid`: session id
- `actsign`: actiom sign
- `subfrm`: sub form
- `seq`: sequence
- `rset`: return set [return data]
- `u`: user
- `c`: captcha
- `p`: password
- `l`: login (std id)
- `lt`: login token
- `act`: action
- `suc`: success
- `war`: warning
- `grd`: grid
- `struc`: struct (json)
- `llogin`: log login
- `f`: form/function
- `nf`: new/next/number/no. form/function
- `cchg`: can change
- `outpar`: output parameters
- `m`: message
- `e`: error
- `ttyp`: tansaction type 
- `ut`: user topic/tag
- `n`: number (len)
- `cmp`: compare
- `ft`: form type
- `dat`: data
- `tit`: title
- `nft`: next form type/tag
- `nopt`: new options
- `r`: [payload data]
- `sguid`: ... generated unique id [seems like randomly generated uuid]
- `ri`:
- `su`: 
- `H`: 
- `F`: field/form
- `C`: column
- `DASHB`: dashboard
- `IDNUMBERCOL`: id number column
- `IDWIDTH`: id width
- `COLTYPE`: column type
- `HLP`: help
- `I`: icon [icon name/css-class]
- `AsYt`: as your time
- `AsYs`: as your ...(date)
- `TRM`/`trm`: term (semester)
- `edu`: education
- `fac`: faculty
- `nav`: navigation
- `BEH`: Behestan 
- `svc`: service