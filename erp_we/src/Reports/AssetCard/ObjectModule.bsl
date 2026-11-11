#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a report in a table document for the specified repair object
//
// Parameters:
// 		ReportTable - SpreadsheetDocument - Table document in which you want to generate the report
// 		Asset - CatalogRef.Assets - The object operation for which you want to generate the report.
//
Procedure GenerateReport(ReportTable, Asset) Export
	
	SubAssetReport = (Type("CatalogRef.SubAssets") = TypeOf(Asset));
	
	Query = New Query;
	Query.SetParameter("Asset", Asset);
	Query.SetParameter("Class", Common.ObjectAttributeValue(Asset, "Class"));
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	
	RequestStructure = New Structure;
	RequestStructure.Insert("RequestCount", 0);
	RequestStructure.Insert("QueryOptions", New Structure);
	GenerateQueryText(Query.Text, RequestStructure);
	
	If RequestStructure.QueryOptions.Count() <> 0 Then
		For Each Parameter In RequestStructure.QueryOptions Do
			Query.SetParameter(Parameter.Key, Parameter.Value);
		EndDo;
	EndIf;
	
	Package = Query.ExecuteBatch();
	
	OutputToSpreadsheetDocument(Package, RequestStructure, ReportTable);
	
EndProcedure

#EndRegion

#Region Private

// Generates the text of the request package and the structure of selections in the package
//
// Parameters:
// 		QueryText - String - String for generating the query package text
// 		RequestStructure - Structure - Structure with names of samples in keys and indexes of query results in values.
//
Procedure GenerateQueryText(QueryText, RequestStructure)
	
	GenerateRequestTextForObjectOfOperation(QueryText, RequestStructure);
	GenerateRequestTextBasedOnPassportCharacteristics(QueryText, RequestStructure);
	GenerateQueryTextForSubordinateNodes(QueryText, RequestStructure);
	GenerateQueryTextBasedOnOperatingHours(QueryText, RequestStructure);
	GenerateTextOfRepairRequest(QueryText, RequestStructure);
	GenerateRequestTextForDefects(QueryText, RequestStructure);
	
EndProcedure

// Generates the text of the request package and the structure of selections in the package
//
// Parameters:
// 		QueryText - String - String for generating the query package text
// 		RequestStructure - Structure - Structure with names of samples in keys and indexes of query results in values.
//
Procedure GenerateRequestTextForObjectOfOperation(QueryText, RequestStructure)
	
	RequestStructure.Insert("Asset", RequestStructure.RequestCount);
	RequestStructure.RequestCount = RequestStructure.RequestCount + 1;
	
	QueryText = QueryText + "
	|////////////////////////////////////////////////////////////////////////////////
	|// DATA OBJECT_ REPAIR_
	|";
	
	QueryText = QueryText +
	"SELECT
	|	Assets.Ref AS Ref,
	|	Assets.Description AS Description,
	|	Assets.DescriptionFull AS DescriptionFull,
	|	UNDEFINED AS Belonging,
	|	Assets.Class AS Class,
	|	Assets.Subclass AS Subclass,
	|	Assets.Status AS Status,
	|	Assets.OperatingBusinessUnit AS OperatingBusinessUnit,
	|	Assets.RMBusinessUnit AS RMBusinessUnit,
	|	Assets.Placement AS Placement,
	|	Assets.Model AS Model,
	|	Assets.SerialNumber AS SerialNumber
	|FROM
	|	Catalog.Assets AS Assets
	|WHERE
	|	Assets.Ref = &Asset
	|
	|UNION ALL
	|
	|SELECT
	|	SubAssets.Ref,
	|	SubAssets.Description,
	|	SubAssets.DescriptionFull,
	|	UNDEFINED,
	|	SubAssets.Class,
	|	SubAssets.Subclass,
	|	SubAssets.Status,
	|	UNDEFINED,
	|	SubAssets.RMBusinessUnit,
	|	SubAssets.Placement,
	|	SubAssets.Model,
	|	SubAssets.SerialNumber
	|FROM
	|	Catalog.SubAssets AS SubAssets
	|WHERE
	|	SubAssets.Ref = &Asset";
	
EndProcedure

// Generates the text of the request package and the structure of selections in the package
//
// Parameters:
// 		QueryText - String - String for generating the query package text
// 		RequestStructure - Structure - Structure with names of samples in keys and indexes of query results in values.
//
Procedure GenerateRequestTextBasedOnPassportCharacteristics(QueryText, RequestStructure)
	
	If Not ThisObject.PassportData Then
		Return;
	EndIf;
	
	RequestStructure.Insert("PassportData", RequestStructure.RequestCount);
	RequestStructure.RequestCount = RequestStructure.RequestCount + 1;
	
	QueryText = QueryText + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// PASSPORTDATA_ CHARACTERISTICS
	|";
	
	QueryText = QueryText +
	"SELECT
	|	AdditionalAttributes.Property AS Characteristic,
	|	AdditionalAttributes.Value AS Value
	|FROM
	|	Catalog.Assets.AdditionalAttributes AS AdditionalAttributes
	|WHERE
	|	AdditionalAttributes.Ref = &Asset
	|
	|ORDER BY
	|	AdditionalAttributes.LineNumber";
	
EndProcedure

// Generates the text of the request package and the structure of selections in the package
//
// Parameters:
// 		QueryText - String - String for generating the query package text
// 		RequestStructure - Structure - Structure with names of samples in keys and indexes of query results in values.
//
Procedure GenerateQueryTextForSubordinateNodes(QueryText, RequestStructure)
	
	If Not ThisObject.Subassemblies Then
		Return;
	EndIf;
	
	RequestStructure.Insert("Subassemblies", RequestStructure.RequestCount);
	RequestStructure.RequestCount = RequestStructure.RequestCount + 1;
	
	QueryText = QueryText + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// SUBORDINATEITEMS NODES
	|";
	
	QueryText = QueryText +
	"SELECT
	|	Nodes.Ref AS Node,
	|	CASE
	|		WHEN Nodes.Parent = &Asset
	|			THEN VALUE(Catalog.SubAssets.EmptyRef)
	|		ELSE Nodes.Parent
	|	END AS Parent,
	|	Nodes.Description AS Description,
	|	UNDEFINED AS CommissioningDate,
	|	UNDEFINED AS OperatingBusinessUnit,
	|	Nodes.RMBusinessUnit AS RMBusinessUnit
	|FROM
	|	Catalog.SubAssets AS Nodes
	|WHERE
	|	(Nodes.Owner IN (&Asset)
	|			OR Nodes.Ref IN HIERARCHY (&Asset)
	|				AND Nodes.Ref <> &Asset)
	|
	|ORDER BY
	|	Nodes.DescriptionFull";
	
EndProcedure

// Generates the text of the request package and the structure of selections in the package
//
// Parameters:
// 		QueryText - String - String for generating the query package text
// 		RequestStructure - Structure - Structure with names of samples in keys and indexes of query results in values.
//
Procedure GenerateQueryTextBasedOnOperatingHours(QueryText, RequestStructure)
	
	If Not ThisObject.RunningTime Then
		Return;
	EndIf;
	
	RequestStructure.Insert("RunningTime", RequestStructure.RequestCount+2);
	RequestStructure.RequestCount = RequestStructure.RequestCount + 3;
	
	QueryText = QueryText + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// RUNNINGTIME
	|";
	
	QueryText = QueryText +
	"SELECT
	|	RunningTimeValues.RunningTimeValue,
	|	RunningTimeValues.CalculateResidualLifetime
	|INTO TTClassSettings
	|FROM
	|	Catalog.MaintenanceSchemes.RunningTimeValues AS RunningTimeValues
	|WHERE
	|	RunningTimeValues.Ref = &Class
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTClassSettings.RunningTimeValue AS RunningTimeValue,
	|	TTClassSettings.CalculateResidualLifetime AS CalculateResidualLifetime,
	|	CASE
	|		WHEN TTClassSettings.CalculateResidualLifetime
	|			THEN ISNULL(ObjectSettings.AssignedResource, ISNULL(NodeSettings.AssignedResource, 0))
	|		ELSE 0
	|	END AS AssignedResource
	|INTO TTIndicatorsOfEarnings
	|FROM
	|	TTClassSettings AS TTClassSettings
	|		LEFT JOIN Catalog.Assets.RunningTimeRecordingParameters AS ObjectSettings
	|		ON TTClassSettings.RunningTimeValue = ObjectSettings.RunningTimeValue
	|			AND (ObjectSettings.Ref = &Asset)
	|		LEFT JOIN Catalog.SubAssets.RunningTimeRecordingParameters AS NodeSettings
	|		ON TTClassSettings.RunningTimeValue = NodeSettings.RunningTimeValue
	|			AND (NodeSettings.Ref = &Asset)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTIndicatorsOfEarnings.RunningTimeValue,
	|	DevelopmentsCut.Period AS RegistrationDate,
	|	DevelopmentsCut.Value AS CurrentValue,
	|	DevelopmentsCut.AverageDailyValue AS AverageDailyValue,
	|	TTIndicatorsOfEarnings.AssignedResource AS AssignedResource,
	|	CASE
	|		WHEN TTIndicatorsOfEarnings.CalculateResidualLifetime
	|			THEN TTIndicatorsOfEarnings.AssignedResource - DevelopmentsCut.Value
	|		ELSE 0
	|	END AS ResidualLifetime,
	|	CASE
	|		WHEN NOT TTIndicatorsOfEarnings.CalculateResidualLifetime
	|				OR DevelopmentsCut.AverageDailyValue IS NULL 
	|				OR DevelopmentsCut.AverageDailyValue = 0
	|			THEN DATETIME(1, 1, 1, 0, 0, 0)
	|		ELSE DATEADD(ISNULL(DevelopmentsCut.Period, DATETIME(1, 1, 1, 0, 0, 0)), DAY, (TTIndicatorsOfEarnings.AssignedResource - ISNULL(DevelopmentsCut.Value, 0)) / ISNULL(DevelopmentsCut.AverageDailyValue, 0))
	|	END AS ProductionDate_,
	|	CASE
	|		WHEN NOT TTIndicatorsOfEarnings.CalculateResidualLifetime
	|				OR DevelopmentsCut.AverageDailyValue IS NULL 
	|				OR DevelopmentsCut.AverageDailyValue = 0
	|			THEN 0
	|		ELSE (TTIndicatorsOfEarnings.AssignedResource - ISNULL(DevelopmentsCut.Value, 0)) / ISNULL(DevelopmentsCut.AverageDailyValue, 0)
	|	END AS ResidualLifetimeInDays
	|FROM
	|	TTIndicatorsOfEarnings AS TTIndicatorsOfEarnings
	|		LEFT JOIN InformationRegister.AssetActivityRecords.SliceLast(
	|				,
	|				(Asset, RunningTimeValue) IN
	|					(SELECT
	|						&Asset,
	|						TTIndicatorsOfEarnings.RunningTimeValue AS RunningTimeValue
	|					FROM
	|						TTIndicatorsOfEarnings AS TTIndicatorsOfEarnings)) AS DevelopmentsCut
	|		ON TTIndicatorsOfEarnings.RunningTimeValue = DevelopmentsCut.RunningTimeValue";
	
EndProcedure

// Generates the text of the request package and the structure of selections in the package
//
// Parameters:
// 		QueryText - String - String for generating the query package text
// 		RequestStructure - Structure - Structure with names of samples in keys and indexes of query results in values.
//
Procedure GenerateTextOfRepairRequest(QueryText, RequestStructure)
	
	ArrayOfStatuses = New Array;
	
	If ThisObject.AssetsMaintenance Then
		ArrayOfStatuses.Add(Enums.RMOrderStatuses.ForCompletion);
		ArrayOfStatuses.Add(Enums.RMOrderStatuses.Running);
	EndIf;
	
	If ThisObject.ClosedRMOrders Then
		ArrayOfStatuses.Add(Enums.RMOrderStatuses.Closed);
	EndIf;
	
	If ArrayOfStatuses.Count() = 0 Then
		Return;
	EndIf;
	
	RequestStructure.Insert("RM", RequestStructure.RequestCount);
	RequestStructure.RequestCount = RequestStructure.RequestCount + 1;
	RequestStructure.QueryOptions.Insert("OrderStatuses", ArrayOfStatuses);
	
	QueryText = QueryText + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// RM
	|";
	
	QueryText = QueryText +
	"SELECT
	|	RMOrder.Number,
	|	RMOrder.Date,
	|	RMOrder.Asset,
	|	RMOrder.Status,
	|	RMOrder.StartDate,
	|	RMOrder.CompletedOn,
	|	RMOrder.Department,
	|	RMOrder.EmployeeResponsible,
	|	RMOrder.RMActivity,
	|	RMOrder.Ref AS Ref
	|FROM
	|	Document.RMOrder AS RMOrder
	|WHERE
	|	(RMOrder.Asset = &Asset
	|			OR RMOrder.RM.Node = &Asset)
	|	AND RMOrder.Status IN(&OrderStatuses)
	|
	|ORDER BY
	|	RMOrder.Status.Order DESC";
	
EndProcedure

// Generates the text of the request package and the structure of selections in the package
//
// Parameters:
// 		QueryText - String - String for generating the query package text
// 		RequestStructure - Structure - Structure with names of samples in keys and indexes of query results in values.
//
Procedure GenerateRequestTextForDefects(QueryText, RequestStructure)
	
	ArrayOfStatuses = New Array;
	
	If ThisObject.CurrentDefects Then
		ArrayOfStatuses.Add(Enums.DefectStatuses.Registered);
		ArrayOfStatuses.Add(Enums.DefectStatuses.RemovalIsDeferred);
		ArrayOfStatuses.Add(Enums.DefectStatuses.Recognized);
	EndIf;
	
	If ThisObject.FixedDefects Then
		ArrayOfStatuses.Add(Enums.DefectStatuses.Fixed);
	EndIf;
	
	If ArrayOfStatuses.Count() = 0 Then
		Return;
	EndIf;
	
	RequestStructure.Insert("Defects", RequestStructure.RequestCount);
	RequestStructure.RequestCount = RequestStructure.RequestCount + 1;
	RequestStructure.QueryOptions.Insert("DefectStatuses", ArrayOfStatuses);
	
	QueryText = QueryText + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// DEFECTS
	|";
	
	QueryText = QueryText +
	"SELECT
	|	RMRequest.Number AS Number,
	|	RMRequest.Date AS Date,
	|	RMRequest.Status AS Status,
	|	RMRequest.Status.Order AS Order,
	|	ISNULL(TableDefectiveNodes.Node, UNDEFINED) AS Node,
	|	ISNULL(TableDefectiveNodes.DefectDetails, """") AS DefectDetails,
	|	RMRequest.EmployeeResponsible AS EmployeeResponsible,
	|	RMRequest.Ref AS Ref
	|FROM
	|	Document.RMRequest AS RMRequest
	|		LEFT JOIN Document.RMRequest.DefectiveSubAssets AS TableDefectiveNodes
	|		ON (TableDefectiveNodes.Ref = RMRequest.Ref)
	|WHERE
	|	RMRequest.Status IN(&DefectStatuses)
	|	AND RMRequest.Asset = &Asset
	|
	|UNION ALL
	|
	|SELECT
	|	RMRequest.Number,
	|	RMRequest.Date,
	|	RMRequest.Status,
	|	RMRequest.Status.Order,
	|	TableDefectiveNodes.Node,
	|	TableDefectiveNodes.DefectDetails,
	|	RMRequest.EmployeeResponsible,
	|	RMRequest.Ref
	|FROM
	|	Document.RMRequest.DefectiveSubAssets AS TableDefectiveNodes
	|		INNER JOIN Document.RMRequest AS RMRequest
	|		ON TableDefectiveNodes.Ref = RMRequest.Ref
	|WHERE
	|	RMRequest.Status IN(&DefectStatuses)
	|	AND TableDefectiveNodes.Node = &Asset
	|
	|ORDER BY
	|	Order DESC";
	
EndProcedure

// Outputs the selection data to a table document
//
// Parameters:
// 		Package - Array - Array of query results
// 		PackageStructure - Structure - Structure of query results in a batch
// 		SpreadsheetDocument - SpreadsheetDocument- Table document for displaying the report.
//
Procedure OutputToSpreadsheetDocument(Package, PackageStructure, SpreadsheetDocument)
	
	Template = ThisObject.GetTemplate("TemplateAssetCard");
	
	If PackageStructure.Property("Asset") And Not Package[PackageStructure.Asset].IsEmpty() Then
		
		DisplayObjectOfOperationInTabularDocument(Package[PackageStructure.Asset].Select(), SpreadsheetDocument, Template);
		
		If PackageStructure.Property("PassportData") And Not Package[PackageStructure.PassportData].IsEmpty() Then
			DisplayPassportCharacteristicsInTabularDocument(Package[PackageStructure.PassportData].Select(), SpreadsheetDocument, Template);
		EndIf;
		
		If PackageStructure.Property("Subassemblies") And Not Package[PackageStructure.Subassemblies].IsEmpty() Then
			OutputSubordinateNodesToTabularDocument(Package[PackageStructure.Subassemblies].Select(), SpreadsheetDocument, Template);
		EndIf;
		
		If PackageStructure.Property("RunningTime") And Not Package[PackageStructure.RunningTime].IsEmpty() Then
			OutputOperatingTimeToTabularDocument(Package[PackageStructure.RunningTime].Select(), SpreadsheetDocument, Template);
		EndIf;
		
		If PackageStructure.Property("RM") And Not Package[PackageStructure.RM].IsEmpty() Then
			DisplayRepairsInTabularDocument(Package[PackageStructure.RM].Select(), SpreadsheetDocument, Template);
		EndIf;
		
		If PackageStructure.Property("Defects") And Not Package[PackageStructure.Defects].IsEmpty() Then
			DisplayDefectsInTabularDocument(Package[PackageStructure.Defects].Select(), SpreadsheetDocument, Template);
		EndIf;
		
		SpreadsheetDocument.EndRowGroup();
		SpreadsheetDocument.PutHorizontalPageBreak();
		
	EndIf;
	
EndProcedure

// Output a selection for an operational object in a table document
//
// Parameters:
// 		Selection - QueryResultSelection - Selection for filling in a table document
// 		SpreadsheetDocument - SpreadsheetDocument - The table document for the report output
// 		Template - SpreadsheetDocument - Table layout document.
//
Procedure DisplayObjectOfOperationInTabularDocument(Selection, SpreadsheetDocument, Template)
	
	Selection.Next();
	
	// Output of the report title
	If ThisObject.SubAssetReport Then
		ReportHeaderTemplate = NStr("vi = 'Chi tiết máy tài sản đang vận hành ""%Description%""';
									|ru = 'Узел объекта эксплуатации ""%Description%""';
									|en = 'The ""%Description%"" sub-asset'; fa = 'The ""%Description%"" sub-asset';
									|it = 'Nodo dell''oggetto di esercizio ""%Description%""';
									|pl = 'Węzeł obiektu eksploatacji ""%Description%""';
									|tr = '""%Description%"" alt varlığı'");
		DataSectionHeader = NStr("vi = 'Dữ liệu chi tiết máy tài sản đang vận hành';
								|ru = 'Данные узла объекта эксплуатации';
								|en = 'Sub-asset data'; fa = 'Sub-asset data';
								|it = 'Dati del nodo dell''oggetto di esercizio';
								|pl = 'Dane węzła obiektu eksploatacji';
								|tr = 'Alt varlık verileri'");
	Else
		ReportHeaderTemplate = NStr("vi = 'tài sản đang vận hành"""" ""%Description%""';
									|ru = 'Объект эксплуатации ""%Description%""';
									|en = 'Asset ""%Description%""'; fa = 'Asset ""%Description%""';
									|it = 'Oggetto di esercizio ""%Description%""';
									|pl = 'Obiekt eksploatacji ""%Description%""';
									|tr = '""%Description%"" varlığı'");
		DataSectionHeader = NStr("vi = 'Dữ liệu tài sản đang vận hành';
								|ru = 'Данные объекта эксплуатации';
								|en = 'Asset data'; fa = 'Asset data';
								|it = 'Dati dell''oggetto di esercizio';
								|pl = 'Dane obiektu eksploatacji';
								|tr = 'Kullanım nesnesi verileri'");
	EndIf;
	
	TemplateArea = Template.GetArea("ReportHeader");
	TemplateArea.Parameters.Title = StrReplace(ReportHeaderTemplate, "%Description%", Selection.DescriptionFull);
	SpreadsheetDocument.Put(TemplateArea);
	SpreadsheetDocument.StartRowGroup("Asset");
	
	// Output of the header of the object data section
	TemplateArea = Template.GetArea("SectionTitle");
	TemplateArea.Parameters.Title = DataSectionHeader;
	SpreadsheetDocument.Put(TemplateArea);
	SpreadsheetDocument.StartRowGroup("RepairObjectData");
	
	// Output of the object data section
	ObjectDataTemplate = New Structure;
	ObjectDataTemplate.Insert("Description", NStr("vi = '<chưa điền>';
													|ru = '<не заполнено>';
													|en = '<not filled in>'; fa = '<not filled in>';
													|it = '<Non compilato>';
													|pl = '<nie wypełniono>';
													|tr = '<doldurulmadı>'"));
	ObjectDataTemplate.Insert("DescriptionFull", NStr("vi = '<chưa điền>';
														|ru = '<не заполнено>';
														|en = '<not filled in>'; fa = '<not filled in>';
														|it = '<Non compilato>';
														|pl = '<nie wypełniono>';
														|tr = '<doldurulmadı>'"));
	ObjectDataTemplate.Insert("Belonging", NStr("vi = '<ở gốc cây>';
												|ru = '<в корне дерева>';
												|en = '<in tree root>'; fa = '<in tree root>';
												|it = '<nella radice dell''albero>';
												|pl = '<w katalogu głównym drzewa>';
												|tr = '<kökte>'"));
	ObjectDataTemplate.Insert("Class", NStr("vi = '<chưa điền>';
											|ru = '<не заполнено>';
											|en = '<Not filled in>'; fa = '<Not filled in>';
											|it = '<Non compilato>';
											|pl = '<nie wypełniono>';
											|tr = '<doldurulmadı>'"));
	ObjectDataTemplate.Insert("Subclass", NStr("vi = '<chưa điền>';
												|ru = '<не заполнено>';
												|en = '<Not filled in>'; fa = '<Not filled in>';
												|it = '<Non compilato>';
												|pl = '<nie wypełniono>';
												|tr = '<doldurulmadı>'"));
	ObjectDataTemplate.Insert("Status", NStr("vi = '<chưa điền>';
											|ru = '<не заполнено>';
											|en = '<Not filled in>'; fa = '<Not filled in>';
											|it = '<Non compilato>';
											|pl = '<nie wypełniono>';
											|tr = '<doldurulmadı>'"));
	ObjectDataTemplate.Insert("RMBusinessUnit", NStr("vi = '<chưa điền>';
													|ru = '<не заполнено>';
													|en = '<not filled in>'; fa = '<not filled in>';
													|it = '<Non compilato>';
													|pl = '<nie wypełniono>';
													|tr = '<doldurulmadı>'"));
	ObjectDataTemplate.Insert("OperatingBusinessUnit", NStr("vi = '<chưa điền>';
															|ru = '<не заполнено>';
															|en = '<not filled in>'; fa = '<not filled in>';
															|it = '<Non compilato>';
															|pl = '<nie wypełniono>';
															|tr = '<doldurulmadı>'"));
	ObjectDataTemplate.Insert("Placement", NStr("vi = '<chưa điền>';
												|ru = '<не заполнено>';
												|en = '<not filled in>'; fa = '<not filled in>';
												|it = '<Non compilato>';
												|pl = '<nie wypełniono>';
												|tr = '<doldurulmadı>'"));
	ObjectDataTemplate.Insert("Model", NStr("vi = '<chưa điền>';
											|ru = '<не заполнено>';
											|en = '<not filled in>'; fa = '<not filled in>';
											|it = '<Non compilato>';
											|pl = '<nie wypełniono>';
											|tr = '<doldurulmadı>'"));
	ObjectDataTemplate.Insert("SerialNumber", NStr("vi = '<chưa điền>';
													|ru = '<не заполнено>';
													|en = '<Not filled in>'; fa = '<Not filled in>';
													|it = '<Non compilato>';
													|pl = '<nie wypełniono>';
													|tr = '<doldurulmadı>'"));
	
	For Each KeyAndValue In ObjectDataTemplate Do
		If ValueIsFilled(Selection[KeyAndValue.Key]) Then
			ObjectDataTemplate[KeyAndValue.Key] = Selection[KeyAndValue.Key];
		EndIf;
	EndDo;
	
	Belonging = Selection.Ref.FullDescr();
	If ValueIsFilled(Belonging) Then
		ObjectDataTemplate.Belonging = Belonging;
	EndIf;
	
	TemplateArea = Template.GetArea("FacilityData");
	TemplateArea.Parameters.Fill(ObjectDataTemplate);
	SpreadsheetDocument.Put(TemplateArea);
	
	SpreadsheetDocument.EndRowGroup();
	
EndProcedure

// Output a selection of passport characteristics in a tabular document
//
// Parameters:
// 		Selection - QueryResultSelection - Selection for filling in a table document
// 		SpreadsheetDocument - SpreadsheetDocument - The table document for the report output
// 		Template - SpreadsheetDocument - Table layout document.
//
Procedure DisplayPassportCharacteristicsInTabularDocument(Selection, SpreadsheetDocument, Template)
	
	// Output of the title of the passport characteristics section
	TemplateArea = Template.GetArea("SectionTitle");
	TemplateArea.Parameters.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đặc điểm hồ sơ -%1';
																									|ru = 'Паспортные характеристики - %1';
																									|en = 'Certificate details - %1'; fa = 'Certificate details - %1';
																									|it = 'Caratteristiche del certificato - %1';
																									|pl = 'Paszportowe charakterystyki - %1';
																									|tr = 'Pasaport özellikleri - %1'"), Selection.Count());
	SpreadsheetDocument.Put(TemplateArea);
	SpreadsheetDocument.StartRowGroup("PassportData");
	
	// Output of passport characteristics
	While Selection.Next() Do
		
		TemplateArea = Template.GetArea("PassportCharacteristicsLine");
		TemplateArea.Parameters.Fill(Selection);
		SpreadsheetDocument.Put(TemplateArea);
		
	EndDo;
	
	SpreadsheetDocument.EndRowGroup();
	
EndProcedure

// Output a selection of subordinate nodes in a table document
//
// Parameters:
// 		Selection - QueryResultSelection - Selection for filling in a table document
// 		SpreadsheetDocument - SpreadsheetDocument - The table document for the report output
// 		Template - SpreadsheetDocument - Table layout document.
//
Procedure OutputSubordinateNodesToTabularDocument(Selection, SpreadsheetDocument, Template)
	
	// Output of the section header of subordinate nodes
	TemplateArea = Template.GetArea("SectionTitle");
	TemplateArea.Parameters.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Chí tiết máy phụ thuộc - %1';
																									|ru = 'Подчиненные узлы - %1';
																									|en = 'Sub-assets - %1'; fa = 'Sub-assets - %1';
																									|it = 'Nodi subordinati - %1';
																									|pl = 'Węzły podrzędne - %1';
																									|tr = 'Bağlı alt varlıklar - %1'"), Selection.Count());
	SpreadsheetDocument.Put(TemplateArea);
	SpreadsheetDocument.StartRowGroup("Subassemblies");
	
	// Table header output
	TemplateArea = Template.GetArea("SubordinateNodesHeader");
	SpreadsheetDocument.Put(TemplateArea);
	
	// Output of subordinate nodes
	ArrayOfSlaveNodes = GetSlaveNodesBySelection(Selection);
	OutputSlaveNodesToTabularDocument(ArrayOfSlaveNodes, SpreadsheetDocument, Template.GetArea("SubordinateNodesString"));
	
	SpreadsheetDocument.EndRowGroup();
	
EndProcedure

// Returns an array of subordinate nodes by parent from the specified selection
//
// Parameters:
// 		Selection - QueryResultSelection - Fetching from a query by object's subordinate nodes
// 		Parent - CatalogRef.SubAssets - Current parent to bypass the selection
// 		Prefixpackagename - Line - Prefix output when printing.
//
// Returns:
// 		Array - Array of subordinate node description structures.
//
Function GetSlaveNodesBySelection(Selection, Parent = Undefined, Val NamePrefix_ = "")
	
	If Parent = Undefined Then
		Parent = Catalogs.SubAssets.EmptyRef();
	EndIf;
	
	ArrayOfSlaveNodes = New Array;
	ParentSearchStructure = New Structure("Parent", Parent);
	
	Selection.Reset();
	While Selection.FindNext(ParentSearchStructure) Do
		
		SlaveNodeStructure = New Structure("Node, Description, CommissioningDate, OperatingBusinessUnit, RMBusinessUnit, Subassemblies");
		FillPropertyValues(SlaveNodeStructure, Selection);
		SlaveNodeStructure.Description = NamePrefix_ + SlaveNodeStructure.Description;
		ArrayOfSlaveNodes.Add(SlaveNodeStructure);
		
	EndDo;
	
	For Each Node In ArrayOfSlaveNodes Do
		Node.Subassemblies = GetSlaveNodesBySelection(Selection, Node.Node, NamePrefix_ + Chars.Tab);
	EndDo;
	
	If ArrayOfSlaveNodes.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	Return ArrayOfSlaveNodes;
	
EndFunction

// Outputs an array of subordinate nodes to a table document
//
// Parameters:
// 		ArrayOfSlaveNodes - Array - Array of structures describing a slave node
// 		SpreadsheetDocument - SpreadsheetDocument - table document of the report
// 		TemplateArea - SpreadsheetDocument - The layout of the output line of the node.
//
Procedure OutputSlaveNodesToTabularDocument(ArrayOfSlaveNodes, SpreadsheetDocument, TemplateArea)
	
	For Each Node In ArrayOfSlaveNodes Do
		
		TemplateArea.Parameters.Fill(Node);
		SpreadsheetDocument.Put(TemplateArea);
		
		If ValueIsFilled(Node.Subassemblies) Then
			OutputSlaveNodesToTabularDocument(Node.Subassemblies, SpreadsheetDocument, TemplateArea);
		EndIf;
		
	EndDo;
	
EndProcedure

// Output a selection based on operating time in a table document
//
// Parameters:
// 		Selection - QueryResultSelection - Selection for filling in a table document
// 		SpreadsheetDocument - SpreadsheetDocument - The table document for the report output
// 		Template - SpreadsheetDocument - Table layout document.
//
Procedure OutputOperatingTimeToTabularDocument(Selection, SpreadsheetDocument, Template)
	
	// Output of the title of the developments section
	TemplateArea = Template.GetArea("SectionTitle");
	TemplateArea.Parameters.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Sản lượng -%1';
																									|ru = 'Наработки - %1';
																									|en = 'Asset activity - %1'; fa = 'Asset activity - %1';
																									|it = 'Tempo senza guasti - %1';
																									|pl = 'Średni czas pracy - %1';
																									|tr = 'Çalışmalar - %1'"), Selection.Count());
	SpreadsheetDocument.Put(TemplateArea);
	SpreadsheetDocument.StartRowGroup("RunningTime");
	
	TemplateArea = Template.GetArea("RunningTimeTitle");
	SpreadsheetDocument.Put(TemplateArea);
	
	While Selection.Next() Do
		
		TemplateArea = Template.GetArea("RunningTimeRow");
		TemplateArea.Parameters.Fill(Selection);
		TemplateArea.Parameters.ResidualTimeResource = RMManagement.ResidualTimeResourceByLine(Selection.ResidualLifetimeInDays);
		SpreadsheetDocument.Put(TemplateArea);
		
	EndDo;
	
	SpreadsheetDocument.EndRowGroup();
	
EndProcedure

// Output a selection of repairs in a table document
//
// Parameters:
// 		Selection - QueryResultSelection - Selection for filling in a table document
// 		SpreadsheetDocument - SpreadsheetDocument - The table document for the report output
// 		Template - SpreadsheetDocument - Table layout document.
//
Procedure DisplayRepairsInTabularDocument(Selection, SpreadsheetDocument, Template)
	
	// Output of the repairs section header
	TemplateArea = Template.GetArea("SectionTitle");
	TemplateArea.Parameters.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Sửa chữa -%1';
																									|ru = 'Ремонты - %1';
																									|en = 'R&M - %1'; fa = 'R&M - %1';
																									|it = 'Riparazioni - %1';
																									|pl = 'Naprawy - %1';
																									|tr = 'Onarımlar - %1'"), Selection.Count());
	SpreadsheetDocument.Put(TemplateArea);
	SpreadsheetDocument.StartRowGroup("RM");
	
	TemplateArea = Template.GetArea("TitleRepairs");
	SpreadsheetDocument.Put(TemplateArea);
	
	While Selection.Next() Do
		
		TemplateArea = Template.GetArea("LineRepairs");
		TemplateArea.Parameters.Fill(Selection);
		TemplateArea.Parameters.NumberAndDate = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Số %1 ngày %2';
																												|ru = '№ %1 от %2';
																												|en = 'No. %1 from %2'; fa = 'No. %1 from %2';
																												|it = '№ %1 da %2';
																												|pl = 'Nr %1 z dnia %2';
																												|tr = '%2 itibarıyla %1 numaralı'"),Selection.Number, Format(Selection.Date, "DLF=DD"));
		SpreadsheetDocument.Put(TemplateArea);
		
	EndDo;
	
	SpreadsheetDocument.EndRowGroup();
	
EndProcedure

// Output a selection of defects in a table document
//
// Parameters:
// 		Selection - QueryResultSelection - Selection for filling in a table document
// 		SpreadsheetDocument - SpreadsheetDocument - The table document for the report output
// 		Template - SpreadsheetDocument - Table layout document.
//
Procedure DisplayDefectsInTabularDocument(Selection, SpreadsheetDocument, Template)
	
	// Output of the defects section header
	TemplateArea = Template.GetArea("SectionTitle");
	TemplateArea.Parameters.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Hỏng hóc -%1';
																									|ru = 'Дефекты - %1';
																									|en = 'Defects - %1'; fa = 'Defects - %1';
																									|it = 'Difetti - %1';
																									|pl = 'Wady - %1';
																									|tr = 'Kusurlar - %1'"), Selection.Count());
	SpreadsheetDocument.Put(TemplateArea);
	SpreadsheetDocument.StartRowGroup("Defects");
	
	TemplateArea = Template.GetArea("DefectsHeader");
	SpreadsheetDocument.Put(TemplateArea);
	
	While Selection.Next() Do
		
		TemplateArea = Template.GetArea("DefectsString");
		TemplateArea.Parameters.Fill(Selection);
		TemplateArea.Parameters.NumberAndDate = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Số %1 ngày %2';
																												|ru = '№ %1 от %2';
																												|en = 'No. %1 from %2'; fa = 'No. %1 from %2';
																												|it = '№ %1 da %2';
																												|pl = 'Nr %1 z dnia %2';
																												|tr = '%2 itibarıyla %1 numaralı'"),Selection.Number, Format(Selection.Date, "DLF=DD"));
		SpreadsheetDocument.Put(TemplateArea);
		
	EndDo;
	
	SpreadsheetDocument.EndRowGroup();
	
EndProcedure

#EndRegion

#EndIf