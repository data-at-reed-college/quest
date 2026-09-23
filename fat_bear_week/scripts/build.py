import pandas as pd
NA = None

sources = pd.DataFrame([
 ("explore_hoc","https://explore.org/hall-of-champions","Explore.org Hall of Champions"),
 ("nps_past","https://www.nps.gov/katm/learn/nature/fat-bear-week-past-and-present.htm","NPS Fat Bear Week: Past and Present"),
 ("wiki","https://en.wikipedia.org/wiki/Fat_Bear_Week","Wikipedia: Fat Bear Week"),
 ("nps_2020_rel","https://www.nps.gov/katm/learn/news/fat-bear-week-2020.htm","NPS 2020 bracket release"),
 ("nps_2021","https://www.nps.gov/katm/learn/fat-bear-week-2021.htm","NPS FBW 2021 bear bios"),
 ("nps_2021_blog","https://www.nps.gov/katm/blogs/fat-bear-week-2021.htm","NPS FBW 2021 recap blog"),
 ("nps_2022","https://www.nps.gov/katm/learn/fat-bear-week-2022.htm","NPS FBW 2022 bear bios"),
 ("nps_2022_rel","https://www.nps.gov/katm/learn/news/fat-bear-week-2022.htm","NPS 2022 schedule release"),
 ("news_12_2023","https://www.12news.com/article/news/nation-world/fat-bear-week-2023-bracket-12-bears-revealed/507-edf2b0be-57d7-46b0-9a1d-6056e82149aa","12News 2023 bracket (12 bears)"),
 ("nps_2023_rel","https://www.nps.gov/katm/learn/news/2023-fat-bear-week-dates-released.htm","NPS 2023 dates release"),
 ("nps_2024","https://www.nps.gov/katm/learn/fat-bear-week-2024.htm?os=i","NPS FBW 2024 bear bios"),
 ("nps_2024_rel","https://www.nps.gov/katm/learn/news/weigh-in-with-fat-bears-at-katmai-national-park-for-fat-bear-week.htm","NPS 2024 release (states 2023 total)"),
 ("npr_2024","https://www.npr.org/2024/10/9/nx-s1-5147101/fat-bear-week-winner-2024","NPR 2024 final"),
 ("usat_2025","https://ca.news.yahoo.com/fat-bear-week-2025-bracket-012707425.html","USA Today 2025 contestants + final votes"),
 ("nbc_2025","https://www.nbcnews.com/news/animal-news/32-chunk-2025s-fat-bear-week-winner-rcna234849","NBC 2025 final (12 contenders)"),
 ("smith_2025","https://www.smithsonianmag.com/smart-news/after-two-years-as-runner-up-chunk-is-finally-crowned-winner-of-fat-bear-week-180987428/","Smithsonian 2025 (states 1.6M total)"),
 ("nps_2026_rel","https://www.nps.gov/katm/learn/news/fat-bear-week-2026.htm","NPS 2026 release"),
 ("usat_2026","https://www.aol.com/articles/fat-bear-week-contestants-revealed-002611000.html","USA Today 2026 contestants"),
 ("unoff_2026","https://unofficialnetworks.com/2026/09/21/fat-bear-week-2026-begins-tomorrow/","2026 full 16-bear list"),
 ("fox_2019","https://www.foxnews.com/great-outdoors/alaskas-fat-bear-week-contest-winner","2019 final votes"),
 ("guardian_2022","https://www.theguardian.com/us-news/2022/oct/11/alaska-fat-bear-week-voting-scandal","2022 ballot-stuffing (via Wikipedia)"),
 ("wiki_otis","https://en.wikipedia.org/wiki/Otis_(bear)","Wikipedia: Otis (not seen 2024-25)"),
], columns=["source_key","url","description"])

# ---------------- years ----------------
years = pd.DataFrame([
 # year,start,end,n_comp,roster_complete,total_votes,total_votes_approx,champion,runner_up,champ_final_votes,ru_final_votes,final_votes_approx,format_notes,sources,notes
 (2014,"2014-09-30","2014-09-30",NA,False,NA,NA,"480","410",NA,NA,NA,"One-day 'Fat Bear Tuesday'; votes were Facebook likes","nps_past;explore_hoc",""),
 (2015,"2015-10-07","2015-10-13",NA,False,NA,NA,"409","480",NA,NA,NA,"First full week","nps_past;explore_hoc",""),
 (2016,NA,NA,NA,False,NA,NA,"480","435",NA,NA,NA,"","explore_hoc",""),
 (2017,NA,NA,NA,False,NA,NA,"480","747",NA,NA,NA,"","explore_hoc","Final described as close"),
 (2018,NA,NA,NA,False,NA,NA,"409","747",NA,NA,NA,"","explore_hoc","409 beat 480 in round 2"),
 (2019,NA,NA,NA,False,NA,NA,"435","775",17500,3600,True,"","explore_hoc;fox_2019","Final ran 12 hours; RU total reported as 'about 3,600'"),
 (2020,"2020-09-30","2020-10-06",NA,False,640000,True,"747","32",NA,NA,NA,"First year voting moved from Facebook to explore.org","explore_hoc;nps_2020_rel","Total reported as 'more than 640,000'; bracket exists only as image"),
 (2021,"2021-09-29","2021-10-05",12,True,793463,False,"480","151",51230,44834,False,"First Fat Bear Junior; junior winner entered main bracket","nps_2021;nps_2021_blog",""),
 (2022,"2022-10-05","2022-10-11",12,True,1000000,True,"747","901",NA,NA,NA,"Fat Bear Junior winner entered main bracket","nps_2022;nps_2022_rel;explore_hoc;wiki","Total 'more than one million'; semifinal ballot-stuffing (fraudulent 435 votes discarded)"),
 (2023,"2023-10-04","2023-10-10",12,True,1300000,True,"128","32",NA,NA,NA,"Fat Bear Junior winner entered main bracket","news_12_2023;nps_2023_rel;explore_hoc;nps_2024_rel","Total CONFLICT: ~1.3M (Explore) vs 'nearly 1.4M' (NPS 2024 release). Final ~2:1 margin"),
 (2024,"2024-10-02","2024-10-08",12,True,1200000,True,"128","32",70000,30000,True,"Start delayed after bear 402 killed on camera","nps_2024;explore_hoc;wiki;npr_2024","Final reported as 'more than 70,000' vs 'approximately 30,000'"),
 (2025,"2025-09-23","2025-09-30",12,True,1700000,True,"32","856",96350,63725,False,"","usat_2025;nbc_2025;explore_hoc;smith_2025;wiki","Total CONFLICT: >1.7M (Explore/NPS) vs >1.6M (Smithsonian) vs >1.5M (Wikipedia)"),
 (2026,"2026-09-22","2026-09-29",16,True,NA,NA,NA,NA,NA,NA,NA,"16 bears; Fat Bear Junior retired, cubs compete with mothers as family units; no weekend voting","nps_2026_rel;usat_2026;unoff_2026","In progress"),
], columns=["year","start_date","end_date","n_competitors","roster_complete","total_votes","total_votes_approx",
            "champion_id","runner_up_id","champion_final_votes","runner_up_final_votes","final_votes_approx",
            "format_notes","sources","notes"])

# ---------------- bears ----------------
# bear_id,name,sex,birth_year_est,birth_year_basis,first_year_identified,mother_id,mother_basis,aliases,sources,notes
B = [
 ("26",NA,"F",NA,NA,NA,"435","believed (USA Today 2025)","", "usat_2025","Arrived 2025 with a new litter"),
 ("32","Chunk","M",2005,"identified as independent 2.5-yr-old in 2007",2007,NA,NA,"","nps_2021;nps_2024","Broken jaw 2025"),
 ("89","Backpack","M",2006,"was 435's yearling in 2007",NA,"435","NPS bio of 435","", "nps_2021",""),
 ("99",NA,NA,2015,"'approximately 10 years old' in 2025",NA,NA,NA,"","usat_2025","Sex not stated in source"),
 ("128","Grazer","F",2004,"CONFLICT: 'young cub in 2005' (2024 bio) vs 'first identified 2009, ~17-19 yrs' (2022 bio)",2005,NA,NA,"","nps_2021;nps_2022;nps_2024","2023 & 2024 champion"),
 ("128-jr","128 Jr.","F",2024,"yearling in 2025",2024,"128","stated","128's yearling","usat_2025;nps_past","2025 Fat Bear Junior champion"),
 ("131",NA,"F",2018,"stated born 2018",2020,NA,NA,"","nps_2021",""),
 ("132",NA,"F",NA,NA,NA,NA,NA,"","nps_2021;usat_2026","Used Brooks River every year since 2009"),
 ("132-cub-2021","132's spring cub",NA,2021,"spring cub in 2021",2021,"132","stated","","nps_2021","2021 Fat Bear Junior champion; sex not stated"),
 ("151","Walker","M",2007,"independent 2-yr-old in 2009",2009,NA,NA,"","nps_2021;nps_2022;nps_2024",""),
 ("164","Bucky","M",2016,"subadult in 2019; ~6 yrs in 2022",2019,NA,NA,"Bucky Dent","nps_2022;nps_2024",""),
 ("284","Electra","F",NA,NA,NA,NA,NA,"","news_12_2023;usat_2026",""),
 ("335",NA,"F",2020,"2.5-yr-old in 2022",2020,"435","stated","","nps_2022",""),
 ("402",NA,"F",NA,NA,NA,NA,NA,"","nps_2021;news_12_2023;wiki","Killed by bear 469 during 2024 FBW; 7-8+ litters"),
 ("409","Beadnose","F",NA,NA,NA,NA,NA,"","explore_hoc","2015 & 2018 champion"),
 ("410",NA,"F",NA,NA,NA,NA,NA,"","explore_hoc","'Elder female', 2014 runner-up"),
 ("428","Studious","F",2020,"3.5-yr-old in 2023",NA,"128","stated","","news_12_2023;usat_2026",""),
 ("435","Holly","F",1997,"young adult/older subadult in 2001; 'mid to late 20s' in 2022",2001,NA,NA,"","nps_2021;nps_2022","2019 champion"),
 ("480","Otis","M",1996,"4-6 yrs old when identified in 2001",2001,NA,NA,"","nps_2021;nps_2022;wiki_otis","Not seen 2024-25; presumed dead"),
 ("503",NA,"M",2013,"left mother at start of 2nd summer (2014)",NA,"402","stated; adopted by 435 in 2014","", "nps_2021;usat_2025",""),
 ("504",NA,"F",NA,NA,NA,NA,NA,"","nps_2024","Competed 2024 with her large cubs"),
 ("519",NA,"F",2021,"'nearly three' in 2024",NA,"719","stated","","nps_2024",""),
 ("602",NA,"M",NA,NA,NA,NA,NA,"","usat_2025",""),
 ("609",NA,"F",2021,"~5 yrs in 2025; LIKELY same bear as 909 Jr.",2021,"909","INFERRED: both described as 2022 Fat Bear Junior champion","909 Jr.; 909's yearling","usat_2025;nps_2022;nps_2024","VERIFY identity with 909 Jr.; adopted by 910 in 2023"),
 ("610",NA,"F",NA,NA,NA,NA,NA,"","usat_2026",""),
 ("620",NA,"F",NA,"subadult in 2026",NA,NA,NA,"","usat_2026",""),
 ("634","Popeye","M",1999,"older subadult in 2002; early 20s in 2021",2002,NA,NA,"","nps_2021",""),
 ("694",NA,"M",NA,"subadult in 2026",NA,NA,NA,"","usat_2026",""),
 ("719",NA,"F",2014,"435's spring cub in 2014",2014,"435","stated","","nps_2021;nps_2024","Non-competitor; mother of 519"),
 ("747",NA,"M",2001,"'a few years old' subadult in 2004",2004,NA,NA,"","nps_2021;nps_2022;nps_2024","2020 & 2022 champion"),
 ("775","Lefty",NA,NA,NA,NA,NA,NA,"","explore_hoc","2019 runner-up; sex not in sources used"),
 ("806",NA,"F",NA,NA,NA,NA,NA,"","news_12_2023;usat_2026","2026: spring cub + adopted 2.5-yr-old ('Biggie')"),
 ("806-jr-2023","806's spring cub","M",2023,"spring cub in 2023",2023,"806","stated","","news_12_2023;nps_past","2023 Fat Bear Junior champion"),
 ("812",NA,"M",2015,"independent 2-yr-old in 2017",2017,"402","believed (NPS bio)","","nps_2021",""),
 ("854","Divot","F",2002,"2.5-yr-old in 2004",2004,NA,NA,"","nps_2022",""),
 ("856",NA,"M",2002,"young adult 2006; ~20 in 2022; ~23 in 2025",2006,NA,NA,"","nps_2022;nps_2024;usat_2025",""),
 ("901",NA,"F",2016,"2.5-yr-old in 2018",2018,NA,NA,"","nps_2022;nps_2024;usat_2025",""),
 ("903","Gully","M",2016,"suspected from 128's 2016 litter",NA,"128","suspected (NPS 2024); stated in 2026 coverage","","nps_2024;usat_2026",""),
 ("909",NA,"F",NA,NA,NA,"409","stated","","nps_2024;usat_2025;usat_2026",""),
 ("910",NA,"F",NA,NA,NA,"409","stated","","nps_2024;usat_2025;usat_2026",""),
]
bears = pd.DataFrame(B, columns=["bear_id","name","sex","birth_year_est","birth_year_basis","first_year_identified",
                                 "mother_id","mother_basis","aliases","sources","notes"])

# ---------------- appearances ----------------
A = []
def add(year, ids, src, complete=True):
    for i in ids:
        A.append(dict(year=year, bear_id=i, source_keys=src))
# partial early years: finalists only
for y,(c,r) in {2014:("480","410"),2015:("409","480"),2016:("480","435"),2017:("480","747"),
                2018:("409","747"),2019:("435","775"),2020:("747","32")}.items():
    add(y,[c,r],"explore_hoc")
add(2018,["480"],"explore_hoc")
add(2021,["32","128","131","132-cub-2021","151","402","435","480","503","634","747","812"],"nps_2021")
add(2022,["32","128","151","164","335","435","480","747","854","856","901","609"],"nps_2022")
add(2023,["32","128","151","164","284","402","428","435","480","747","806-jr-2023","901"],"news_12_2023")
add(2024,["32","128","151","164","504","519","747","856","901","903","909","609"],"nps_2024")
add(2025,["26","32","99","128","128-jr","503","602","609","856","901","909","910"],"usat_2025")
add(2026,["132","284","610","806","901","620","694","909","428","131","910","32","164","151","903","89"],"usat_2026;unoff_2026")
app = pd.DataFrame(A)

champ = {r.year:r.champion_id for r in years.itertuples()}
ru = {r.year:r.runner_up_id for r in years.itertuples()}
def result(r):
    if r.year == 2026: return "in_progress"
    if champ.get(r.year) == r.bear_id: return "champion"
    if ru.get(r.year) == r.bear_id: return "runner_up"
    if r.year == 2022 and r.bear_id == "435": return "semifinal"
    if r.year == 2018 and r.bear_id == "480": return "round_2"
    return "eliminated_round_unknown"
app["result"] = app.apply(result, axis=1)

fam = {(2026,"132"):3,(2026,"284"):2,(2026,"610"):2,(2026,"806"):2,(2026,"901"):1,(2024,"504"):NA}
app["entry_type"] = "individual"
for (y,b) in fam: app.loc[(app.year==y)&(app.bear_id==b),"entry_type"]="family_unit"
cubs = {(2021,"132-cub-2021"),(2022,"609"),(2023,"806-jr-2023"),(2024,"609"),(2025,"128-jr")}
for (y,b) in cubs: app.loc[(app.year==y)&(app.bear_id==b),"entry_type"]="cub"
app["n_cubs_in_entry"] = [fam.get((r.year,r.bear_id), NA) if r.entry_type=="family_unit" else NA for r in app.itertuples()]
notes = {(2022,"609"):"listed as '909's Yearling Cub' (Fat Bear Junior winner)",
         (2024,"609"):"listed as '909 Jr.' (Fat Bear Junior winner); raised by 910",
         (2024,"504"):"number of cubs not stated",
         (2023,"402"):"", (2025,"26"):"arrived with new litter; unclear if entered as family unit",
         (2026,"806"):"spring cub + adopted 2.5-yr-old",(2026,"909"):"lost two cubs this season",
         (2023,"901"):"had cubs (one disappeared mid-Sept); entered individually"}
app["notes"] = [notes.get((r.year,r.bear_id),"") for r in app.itertuples()]
app["roster_complete_for_year"] = app.year >= 2021
app = app.sort_values(["year","bear_id"])[["year","bear_id","entry_type","n_cubs_in_entry","result","roster_complete_for_year","source_keys","notes"]]

# checks
missing = set(app.bear_id) - set(bears.bear_id)
assert not missing, missing
counts = app[app.year>=2021].groupby("year").size()
print(counts.to_dict())
for y in range(2021,2027):
    assert counts[y] == years.set_index("year").n_competitors[y], y

for c in ["n_competitors","total_votes","champion_final_votes","runner_up_final_votes"]:
    years[c]=years[c].astype("Int64")
for c in ["birth_year_est","first_year_identified"]:
    bears[c]=bears[c].astype("Int64")
app["n_cubs_in_entry"]=app["n_cubs_in_entry"].astype("Int64")
years.to_csv("years.csv", index=False)
bears.to_csv("bears.csv", index=False)
app.to_csv("appearances.csv", index=False)
sources.to_csv("sources.csv", index=False)
print(len(bears), len(app))
