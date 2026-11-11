let
    Source = Excel.Workbook(File.Contents("C:\path\to\wuenic2025rev_web-update.xlsx"), null, true),
    country_Sheet = Source{[Item="country",Kind="Sheet"]}[Data],
    #"Promoted Headers" = Table.PromoteHeaders(country_Sheet, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"iso3c", type text}, {"country", type text}, {"vaccine", type text}, {"year", Int64.Type}, {"target_grp", type text}, {"coverage", Int64.Type}, {"source", type text}, {"unicef", type text}, {"gavi", type text}, {"world_bank", type text}, {"world_bank_fcv", type text}, {"who", type text}, {"who_fcv", type text}, {"african_union", type any}, {"european_union", type any}}),
    #"Keep 6 columns" = Table.SelectColumns(#"Changed Type",{"iso3c", "country", "vaccine", "year", "target_grp", "coverage"}),
    #"Filter scope" = Table.SelectRows(#"Keep 6 columns", each [year] >= 2000
        and List.Contains({"BEN","BFA","CIV","CPV","GHA","GIN","GMB","GNB","LBR","MLI","MRT","NER","NGA","SEN","SLE","TGO"}, [iso3c])
        and List.Contains({"dtp1","dtp3","mcv1","mcv2"}, [vaccine]))
in
    #"Filter scope"