<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">

  <!-- MARC Code List for Countries -->
  <xsl:variable name="marcCountryCodes">
    <country code="aa">Albania</country>
    <country code="abc">Alberta</country>
    <country code="ac" status="discontinued">Ashmore and Cartier Islands</country>
    <country code="aca">Australian Capital Territory</country>
    <country code="ae">Algeria</country>
    <country code="af">Afghanistan</country>
    <country code="ag">Argentina</country>
    <country code="ai" status="discontinued">Anguilla</country>
    <country code="ai">Armenia (Republic)</country>
    <country code="air" status="discontinued">Armenian S.S.R.</country>
    <country code="aj">Azerbaijan</country>
    <country code="ajr" status="discontinued">Azerbaijan S.S.R.</country>
    <country code="aku">Alaska</country>
    <country code="alu">Alabama</country>
    <country code="am">Anguilla</country>
    <country code="an">Andorra</country>
    <country code="ao">Angola</country>
    <country code="aq">Antigua and Barbuda</country>
    <country code="aru">Arkansas</country>
    <country code="as">American Samoa</country>
    <country code="at">Australia</country>
    <country code="au">Austria</country>
    <country code="aw">Aruba</country>
    <country code="ay">Antarctica</country>
    <country code="azu">Arizona</country>
    <country code="ba">Bahrain</country>
    <country code="bb">Barbados</country>
    <country code="bcc">British Columbia</country>
    <country code="bd">Burundi</country>
    <country code="be">Belgium</country>
    <country code="bf">Bahamas</country>
    <country code="bg">Bangladesh</country>
    <country code="bh">Belize</country>
    <country code="bi">British Indian Ocean Territory</country>
    <country code="bl">Brazil</country>
    <country code="bm">Bermuda Islands</country>
    <country code="bn">Bosnia and Herzegovina</country>
    <country code="bo">Bolivia</country>
    <country code="bp">Solomon Islands</country>
    <country code="br">Burma</country>
    <country code="bs">Botswana</country>
    <country code="bt">Bhutan</country>
    <country code="bu">Bulgaria</country>
    <country code="bv">Bouvet Island</country>
    <country code="bw">Belarus</country>
    <country code="bwr" status="discontinued">Byelorussian S.S.R.</country>
    <country code="bx">Brunei</country>
    <country code="ca">Caribbean Netherlands</country>
    <country code="cau">California</country>
    <country code="cb">Cambodia</country>
    <country code="cc">China</country>
    <country code="cd">Chad</country>
    <country code="ce">Sri Lanka</country>
    <country code="cf">Congo (Brazzaville)</country>
    <country code="cg">Congo (Democratic Republic)</country>
    <country code="ch">China (Republic : 1949- )</country>
    <country code="ci">Croatia</country>
    <country code="cj">Cayman Islands</country>
    <country code="ck">Colombia</country>
    <country code="cl">Chile</country>
    <country code="cm">Cameroon</country>
    <country code="cn" status="discontinued">Canada</country>
    <country code="co">Curaçao</country>
    <country code="cou">Colorado</country>
    <country code="cp" status="discontinued">Canton and Enderbury Islands</country>
    <country code="cq">Comoros</country>
    <country code="cr">Costa Rica</country>
    <country code="cs" status="discontinued">Czechoslovakia</country>
    <country code="ctu">Connecticut</country>
    <country code="cu">Cuba</country>
    <country code="cv">Cabo Verde</country>
    <country code="cw">Cook Islands</country>
    <country code="cx">Central African Republic</country>
    <country code="cy">Cyprus</country>
    <country code="cz" status="discontinued">Canal Zone</country>
    <country code="dcu">District of Columbia</country>
    <country code="deu">Delaware</country>
    <country code="dk">Denmark</country>
    <country code="dm">Benin</country>
    <country code="dq">Dominica</country>
    <country code="dr">Dominican Republic</country>
    <country code="ea">Eritrea</country>
    <country code="ec">Ecuador</country>
    <country code="eg">Equatorial Guinea</country>
    <country code="em">Timor-Leste</country>
    <country code="enk">England</country>
    <country code="er">Estonia</country>
    <country code="err" status="discontinued">Estonia</country>
    <country code="es">El Salvador</country>
    <country code="et">Ethiopia</country>
    <country code="fa">Faroe Islands</country>
    <country code="fg">French Guiana</country>
    <country code="fi">Finland</country>
    <country code="fj">Fiji</country>
    <country code="fk">Falkland Islands</country>
    <country code="flu">Florida</country>
    <country code="fm">Micronesia (Federated States)</country>
    <country code="fp">French Polynesia</country>
    <country code="fr">France</country>
    <country code="fs">Terres australes et antarctiques françaises</country>
    <country code="ft">Djibouti</country>
    <country code="gau">Georgia</country>
    <country code="gb">Kiribati</country>
    <country code="gd">Grenada</country>
    <country code="ge" status="discontinued">Germany (East)</country>
    <country code="gg">Guernsey</country>
    <country code="gh">Ghana</country>
    <country code="gi">Gibraltar</country>
    <country code="gl">Greenland</country>
    <country code="gm">Gambia</country>
    <country code="gn" status="discontinued">Gilbert and Ellice Islands</country>
    <country code="go">Gabon</country>
    <country code="gp">Guadeloupe</country>
    <country code="gr">Greece</country>
    <country code="gs">Georgia (Republic)</country>
    <country code="gsr" status="discontinued">Georgian S.S.R.</country>
    <country code="gt">Guatemala</country>
    <country code="gu">Guam</country>
    <country code="gv">Guinea</country>
    <country code="gw">Germany</country>
    <country code="gy">Guyana</country>
    <country code="gz">Gaza Strip</country>
    <country code="hiu">Hawaii</country>
    <country code="hk" status="discontinued">Hong Kong</country>
    <country code="hm">Heard and McDonald Islands</country>
    <country code="ho">Honduras</country>
    <country code="ht">Haiti</country>
    <country code="hu">Hungary</country>
    <country code="iau">Iowa</country>
    <country code="ic">Iceland</country>
    <country code="idu">Idaho</country>
    <country code="ie">Ireland</country>
    <country code="ii">India</country>
    <country code="ilu">Illinois</country>
    <country code="im">Isle of Man</country>
    <country code="inu">Indiana</country>
    <country code="io">Indonesia</country>
    <country code="iq">Iraq</country>
    <country code="ir">Iran</country>
    <country code="is">Israel</country>
    <country code="it">Italy</country>
    <country code="iu" status="discontinued">Israel-Syria Demilitarized Zones</country>
    <country code="iv">Côte d'Ivoire</country>
    <country code="iw" status="discontinued">Israel-Jordan Demilitarized Zones</country>
    <country code="iy">Iraq-Saudi Arabia Neutral Zone</country>
    <country code="ja">Japan</country>
    <country code="je">Jersey</country>
    <country code="ji">Johnston Atoll</country>
    <country code="jm">Jamaica</country>
    <country code="jn" status="discontinued">Jan Mayen</country>
    <country code="jo">Jordan</country>
    <country code="ke">Kenya</country>
    <country code="kg">Kyrgyzstan</country>
    <country code="kgr" status="discontinued">Kirghiz S.S.R.</country>
    <country code="kn">Korea (North)</country>
    <country code="ko">Korea (South)</country>
    <country code="ksu">Kansas</country>
    <country code="ku">Kuwait</country>
    <country code="kv">Kosovo</country>
    <country code="kyu">Kentucky</country>
    <country code="kz">Kazakhstan</country>
    <country code="kzr" status="discontinued">Kazakh S.S.R.</country>
    <country code="lau">Louisiana</country>
    <country code="lb">Liberia</country>
    <country code="le">Lebanon</country>
    <country code="lh">Liechtenstein</country>
    <country code="li">Lithuania</country>
    <country code="lir" status="discontinued">Lithuania</country>
    <country code="ln" status="discontinued">Central and Southern Line Islands</country>
    <country code="lo">Lesotho</country>
    <country code="ls">Laos</country>
    <country code="lu">Luxembourg</country>
    <country code="lv">Latvia</country>
    <country code="lvr" status="discontinued">Latvia</country>
    <country code="ly">Libya</country>
    <country code="mau">Massachusetts</country>
    <country code="mbc">Manitoba</country>
    <country code="mc">Monaco</country>
    <country code="mdu">Maryland</country>
    <country code="meu">Maine</country>
    <country code="mf">Mauritius</country>
    <country code="mg">Madagascar</country>
    <country code="mh" status="discontinued">Macao</country>
    <country code="miu">Michigan</country>
    <country code="mj">Montserrat</country>
    <country code="mk">Oman</country>
    <country code="ml">Mali</country>
    <country code="mm">Malta</country>
    <country code="mnu">Minnesota</country>
    <country code="mo">Montenegro</country>
    <country code="mou">Missouri</country>
    <country code="mp">Mongolia</country>
    <country code="mq">Martinique</country>
    <country code="mr">Morocco</country>
    <country code="msu">Mississippi</country>
    <country code="mtu">Montana</country>
    <country code="mu">Mauritania</country>
    <country code="mv">Moldova</country>
    <country code="mvr" status="discontinued">Moldavian S.S.R.</country>
    <country code="mw">Malawi</country>
    <country code="mx">Mexico</country>
    <country code="my">Malaysia</country>
    <country code="mz">Mozambique</country>
    <country code="na" status="discontinued">Netherlands Antilles</country>
    <country code="nbu">Nebraska</country>
    <country code="ncu">North Carolina</country>
    <country code="ndu">North Dakota</country>
    <country code="ne">Netherlands</country>
    <country code="nfc">Newfoundland and Labrador</country>
    <country code="ng">Niger</country>
    <country code="nhu">New Hampshire</country>
    <country code="nik">Northern Ireland</country>
    <country code="nju">New Jersey</country>
    <country code="nkc">New Brunswick</country>
    <country code="nl">New Caledonia</country>
    <country code="nm" status="discontinued">Northern Mariana Islands</country>
    <country code="nmu">New Mexico</country>
    <country code="nn">Vanuatu</country>
    <country code="no">Norway</country>
    <country code="np">Nepal</country>
    <country code="nq">Nicaragua</country>
    <country code="nr">Nigeria</country>
    <country code="nsc">Nova Scotia</country>
    <country code="ntc">Northwest Territories</country>
    <country code="nu">Nauru</country>
    <country code="nuc">Nunavut</country>
    <country code="nvu">Nevada</country>
    <country code="nw">Northern Mariana Islands</country>
    <country code="nx">Norfolk Island</country>
    <country code="nyu">New York (State)</country>
    <country code="nz">New Zealand</country>
    <country code="ohu">Ohio</country>
    <country code="oku">Oklahoma</country>
    <country code="onc">Ontario</country>
    <country code="oru">Oregon</country>
    <country code="ot">Mayotte</country>
    <country code="pau">Pennsylvania</country>
    <country code="pc">Pitcairn Island</country>
    <country code="pe">Peru</country>
    <country code="pf">Paracel Islands</country>
    <country code="pg">Guinea-Bissau</country>
    <country code="ph">Philippines</country>
    <country code="pic">Prince Edward Island</country>
    <country code="pk">Pakistan</country>
    <country code="pl">Poland</country>
    <country code="pn">Panama</country>
    <country code="po">Portugal</country>
    <country code="pp">Papua New Guinea</country>
    <country code="pr">Puerto Rico</country>
    <country code="pt" status="discontinued">Portuguese Timor</country>
    <country code="pw">Palau</country>
    <country code="py">Paraguay</country>
    <country code="qa">Qatar</country>
    <country code="qea">Queensland</country>
    <country code="quc">Québec (Province)</country>
    <country code="rb">Serbia</country>
    <country code="re">Réunion</country>
    <country code="rh">Zimbabwe</country>
    <country code="riu">Rhode Island</country>
    <country code="rm">Romania</country>
    <country code="ru">Russia (Federation)</country>
    <country code="rur" status="discontinued">Russian S.F.S.R.</country>
    <country code="rw">Rwanda</country>
    <country code="ry" status="discontinued">Ryukyu Islands, Southern</country>
    <country code="sa">South Africa</country>
    <country code="sb" status="discontinued">Svalbard</country>
    <country code="sc">Saint-Barthélemy</country>
    <country code="scu">South Carolina</country>
    <country code="sd">South Sudan</country>
    <country code="sdu">South Dakota</country>
    <country code="se">Seychelles</country>
    <country code="sf">Sao Tome and Principe</country>
    <country code="sg">Senegal</country>
    <country code="sh">Spanish North Africa</country>
    <country code="si">Singapore</country>
    <country code="sj">Sudan</country>
    <country code="sk" status="discontinued">Sikkim</country>
    <country code="sl">Sierra Leone</country>
    <country code="sm">San Marino</country>
    <country code="sn">Sint Maarten</country>
    <country code="snc">Saskatchewan</country>
    <country code="so">Somalia</country>
    <country code="sp">Spain</country>
    <country code="sq">Eswatini</country>
    <country code="sr">Surinam</country>
    <country code="ss">Western Sahara</country>
    <country code="st">Saint-Martin</country>
    <country code="stk">Scotland</country>
    <country code="su">Saudi Arabia</country>
    <country code="sv" status="discontinued">Swan Islands</country>
    <country code="sw">Sweden</country>
    <country code="sx">Namibia</country>
    <country code="sy">Syria</country>
    <country code="sz">Switzerland</country>
    <country code="ta">Tajikistan</country>
    <country code="tar" status="discontinued">Tajik S.S.R.</country>
    <country code="tc">Turks and Caicos Islands</country>
    <country code="tg">Togo</country>
    <country code="th">Thailand</country>
    <country code="ti">Tunisia</country>
    <country code="tk">Turkmenistan</country>
    <country code="tkr" status="discontinued">Turkmen S.S.R.</country>
    <country code="tl">Tokelau</country>
    <country code="tma">Tasmania</country>
    <country code="tnu">Tennessee</country>
    <country code="to">Tonga</country>
    <country code="tr">Trinidad and Tobago</country>
    <country code="ts">United Arab Emirates</country>
    <country code="tt" status="discontinued">Trust Territory of the Pacific Islands</country>
    <country code="tu">Turkey</country>
    <country code="tv">Tuvalu</country>
    <country code="txu">Texas</country>
    <country code="tz">Tanzania</country>
    <country code="ua">Egypt</country>
    <country code="uc">United States Misc. Caribbean Islands</country>
    <country code="ug">Uganda</country>
    <country code="ui" status="discontinued">United Kingdom Misc. Islands</country>
    <country code="uik" status="discontinued">United Kingdom Misc. Islands</country>
    <country code="uk" status="discontinued">United Kingdom</country>
    <country code="un">Ukraine</country>
    <country code="unr" status="discontinued">Ukraine</country>
    <country code="up">United States Misc. Pacific Islands</country>
    <country code="ur" status="discontinued">Soviet Union</country>
    <country code="us" status="discontinued">United States</country>
    <country code="utu">Utah</country>
    <country code="uv">Burkina Faso</country>
    <country code="uy">Uruguay</country>
    <country code="uz">Uzbekistan</country>
    <country code="uzr" status="discontinued">Uzbek S.S.R.</country>
    <country code="vau">Virginia</country>
    <country code="vb">British Virgin Islands</country>
    <country code="vc">Vatican City</country>
    <country code="ve">Venezuela</country>
    <country code="vi">Virgin Islands of the United States</country>
    <country code="vm">Vietnam</country>
    <country code="vn" status="discontinued">Vietnam, North</country>
    <country code="vp">Various places</country>
    <country code="vra">Victoria</country>
    <country code="vs" status="discontinued">Vietnam, South</country>
    <country code="vtu">Vermont</country>
    <country code="wau">Washington (State)</country>
    <country code="wb" status="discontinued">West Berlin</country>
    <country code="wea">Western Australia</country>
    <country code="wf">Wallis and Futuna</country>
    <country code="wiu">Wisconsin</country>
    <country code="wj">West Bank of the Jordan River</country>
    <country code="wk">Wake Island</country>
    <country code="wlk">Wales</country>
    <country code="ws">Samoa</country>
    <country code="wvu">West Virginia</country>
    <country code="wyu">Wyoming</country>
    <country code="xa">Christmas Island (Indian Ocean)</country>
    <country code="xb">Cocos (Keeling) Islands</country>
    <country code="xc">Maldives</country>
    <country code="xd">Saint Kitts-Nevis</country>
    <country code="xe">Marshall Islands</country>
    <country code="xf">Midway Islands</country>
    <country code="xga">Coral Sea Islands Territory</country>
    <country code="xh">Niue</country>
    <country code="xi" status="discontinued">Saint Kitts-Nevis-Anguilla</country>
    <country code="xj">Saint Helena</country>
    <country code="xk">Saint Lucia</country>
    <country code="xl">Saint Pierre and Miquelon</country>
    <country code="xm">Saint Vincent and the Grenadines</country>
    <country code="xn">North Macedonia</country>
    <country code="xna">New South Wales</country>
    <country code="xo">Slovakia</country>
    <country code="xoa">Northern Territory</country>
    <country code="xp">Spratly Island</country>
    <country code="xr">Czech Republic</country>
    <country code="xra">South Australia</country>
    <country code="xs">South Georgia and the South Sandwich Islands</country>
    <country code="xv">Slovenia</country>
    <country code="xx">No place, unknown, or undetermined</country>
    <country code="xxc">Canada</country>
    <country code="xxk">United Kingdom</country>
    <country code="xxr" status="discontinued">Soviet Union</country>
    <country code="xxu">United States</country>
    <country code="ye">Yemen</country>
    <country code="ykc">Yukon Territory</country>
    <country code="ys" status="discontinued">Yemen (People's Democratic Republic)</country>
    <country code="yu" status="discontinued">Serbia and Montenegro</country>
    <country code="za">Zambia</country>
  </xsl:variable>
</xsl:stylesheet>
