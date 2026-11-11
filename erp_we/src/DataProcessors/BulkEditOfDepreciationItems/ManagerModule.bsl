#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region DownloadingFromVHFFile

// Overrides the parameters for loading data from a file.
//
// Parameters:
//  Parameters - Structure:
//   * DataStructureTemplateName - String - the name of the layout. For example, "Uploading a file".
//   * TabularSectionName - String - The full name of the table part. For example, "Document._account to the payer.The table is missing.Products"
//   * RequiredColumns2 - Array of String - names of required columns.
//   * ColumnDataType - Map of KeyAndValue:
//      * Key - String - column name;
//      * Value - TypeDescription - the type of the column of uploaded data.
//   * AdditionalParameters - Structure
//
Procedure SetDownloadParametersFromVHFFile(Parameters) Export

EndProcedure

// Compares the data loaded in the table part of the full table part
// With the data in the IB, and fills in the parameters of the addressable Comparison and the list of one-Values.
// 
// Parameters:
// 	AddressOfUploadedData- String - address of the temporary storage with a table of values that
//                                   contains the downloaded data from the file.
// 	AddressOfMappingTable - String - the address of the temporary storage with an empty table of values,
//                                       which is a copy of the table part of the document 
//                                       that needs to be filled in from the addressable Data table.
// 	ConflictsList - ValueTable - consists of:
//  * Id - Number - Id
//  * Column - String - column name
// 	FullTabularSectionName - String - full name of the table part
// 	AdditionalParameters - Structure - additional parameters passed from the source form.
//
Procedure MapDataToImport(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, FullTabularSectionName, AdditionalParameters) Export
	
	FixedAssets = GetFromTempStorage(AddressOfMappingTable); // ValueTable
	DataToImport = GetFromTempStorage(AddressOfUploadedData); // ValueTable
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = 
		"SELECT
		|	CAST(DataForComparison.AssetID AS STRING(15)) AS AssetID,
		|	DataForComparison.FixedAsset AS FixedAsset,
		|	DataForComparison.Id AS Id
		|INTO DataForComparison
		|FROM
		|	&DataForComparison AS DataForComparison
		|
		|INDEX BY
		|	AssetID
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Assets.Ref AS Ref,
		|	Assets.Ref.AssetID AS AssetID,
		|	DataForComparison.Id AS Id
		|INTO MatchedProductsByInventoryNumber
		|FROM
		|	DataForComparison AS DataForComparison
		|		INNER JOIN Catalog.Assets AS Assets
		|		ON (Assets.Ref.AssetID = DataForComparison.AssetID)
		|		AND (DataForComparison.AssetID <> """")
		|
		|INDEX BY
		|	Id
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DataForComparison.FixedAsset AS FixedAsset,
		|	DataForComparison.Id AS Id
		|INTO DataForMatchingByName
		|FROM
		|	DataForComparison AS DataForComparison
		|		LEFT JOIN MatchedProductsByInventoryNumber AS MatchedProductsByInventoryNumber
		|		ON DataForComparison.Id = MatchedProductsByInventoryNumber.Id
		|WHERE
		|	MatchedProductsByInventoryNumber.Id IS NULL
		|
		|INDEX BY
		|	Id
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MAX(Assets.Ref) AS Ref,
		|	DataForMatchingByName.Id AS Id,
		|	COUNT(DataForMatchingByName.Id) AS Count
		|FROM
		|	DataForMatchingByName AS DataForMatchingByName
		|		INNER JOIN Catalog.Assets AS Assets
		|		ON (Assets.Description = (CAST(DataForMatchingByName.FixedAsset AS
		|			STRING(500))))
		|GROUP BY
		|	DataForMatchingByName.Id
		|
		|UNION ALL
		|
		|SELECT
		|	MAX(MatchedProductsByInventoryNumber.Ref),
		|	MatchedProductsByInventoryNumber.Id,
		|	COUNT(MatchedProductsByInventoryNumber.Id)
		|FROM
		|	MatchedProductsByInventoryNumber AS MatchedProductsByInventoryNumber
		|GROUP BY
		|	MatchedProductsByInventoryNumber.Id";

	Query.SetParameter("DataForComparison", DataToImport);
	QueriesResults = Query.ExecuteBatch(); // Array of QueryResult
	
	FATable = QueriesResults[3].Unload(); // ValueTable

	For Each TableRow In DataToImport Do
		
		FA = FixedAssets.Add();
		FA.Id = TableRow.Id;
		FA.UsefulLifeAccounting = TableRow.UsefulLifeAccounting;
		FA.UsefulLifeManagementAccounting = TableRow.UsefulLifeManagementAccounting;
		FA.EstimatedRunningTime = TableRow.EstimatedRunningTime;
		FA.ResidualValueLocal = TableRow.ResidualValueLocal;
		FA.ResidualValueMan = TableRow.ResidualValueMan;
		
		FAString = FATable.Find(TableRow.Id, "Id");
		If FAString <> Undefined Then 
			If FAString.Count = 1 Then 
				FA.FixedAsset = FAString.Ref;
				FA.AssetID = TableRow.AssetID;
			ElsIf FAString.Count > 1 Then
				WritingAboutAmbiguity = ConflictsList.Add();
				WritingAboutAmbiguity.Id = TableRow.Id;
				WritingAboutAmbiguity.Column = "FixedAsset";
			EndIf;
		EndIf;
	EndDo;
	
	PutToTempStorage(FixedAssets, AddressOfMappingTable);
	
EndProcedure

#EndRegion

// Returns the parameters of the selection of articles and analyst.
// 
// Returns:
//	See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Function ItemsAndDimensionsSelectionParameters() Export
	
	ArticleSelectionAndAnalyticsOptions = New Array;
	
	// ExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.ArticleType = "ExpenseItemItemType";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("AssetsLiabilitiesDimension");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);
	
	// IncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "IncomeItem";
	ChoiceParameters.ArticleType = "IncomeItemItemType";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";

	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesIncomeDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItem");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("AssetsLiabilitiesIncomeDimension");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);
	
	Return ArticleSelectionAndAnalyticsOptions;
	
EndFunction

// Returns the accounting account settings.
//  
// Returns:
//	See GLAccountSettingsServer.SetupParameters
//
Function AccountingAccountSettings_() Export
	
	ParametersArray = New Array();
	
	#Region SettingUpPresentationOfExpensesInLocalAccounting
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	SetupParameters.GLAccountSettings = "GLAccountSettings";
	SetupParameters.AssetAndLiabilityItem = "ExpenseItem";
	SetupParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	SetupParameters.Presentation = "PresentationOfTheCostReflectionInTheReglAccounting";
	SetupParameters.ArticleType     = "ExpenseItemItemType";
	
	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("PresentationOfTheCostReflectionInTheReglAccounting");
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
		
	#Region SettingUpPresentationOfExpensesInLocalAccounting
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	SetupParameters.GLAccountSettings = "IncomeLedgerAccountsSettings";
	SetupParameters.AssetAndLiabilityItem = "IncomeItem";
	SetupParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesIncomeDimension";
	SetupParameters.Presentation = "PresentationOfTheIncomeReflectionInTheReglAccounting";
	SetupParameters.ArticleType     = "IncomeItemItemType";

	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("PresentationOfTheIncomeReflectionInTheReglAccounting");
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	Return ParametersArray;
	
EndFunction

Procedure CreateDocumentsInBackgroundOnServer(Parameters) Export
	
	BeginTransaction();
	Try
		For Each String In Parameters.FixedAssets Do
			
			ReflectVBAForLine = (String.BUState <> Enums.FixedAssetsStates.TakenOffBooks
										And String.BUState <> Enums.FixedAssetsStates.NotRecognized_
										And String.BUState <> Enums.FixedAssetsStates.LeaseContractsSigned
										And String.BUState <> Enums.FixedAssetsStates.EnteredInOffBalanceAccounting
										And Parameters.PostInAccounting);
			ReflectVueForString = (String.StateOfTheUU <> Enums.FixedAssetsStates.TakenOffBooks
										And String.StateOfTheUU <> Enums.FixedAssetsStates.NotRecognized_
										And String.StateOfTheUU <> Enums.FixedAssetsStates.LeaseContractsSigned
										And String.StateOfTheUU <> Enums.FixedAssetsStates.EnteredInOffBalanceAccounting
										And Parameters.RecordInMA);

			If ValueIsFilled(String.CostAdjustmentDocument)
				Or String.Organization <> Parameters.Organization
				Or (Not ReflectVBAForLine And Not ReflectVueForString)
				Or Not (ValueIsFilled(String.UsefulLifeAccounting)
					Or ValueIsFilled(String.UsefulLifeAccounting)
					Or ValueIsFilled(String.UsefulLifeManagementAccounting)
					Or ValueIsFilled(String.EstimatedRunningTime)
					Or ValueIsFilled(String.ResidualValueLocal)
					Or ValueIsFilled(String.ResidualValueMan)) Then
				Continue;
			Else
				BeginTransaction();
				
				Try
					// Creating a document with parameter CHANGE_2_4
					NewDocumentChangingFASettings = Documents.ChangeFixedAssetFinancialDetails2_4.CreateDocument();
					NewDocumentChangingFASettings.Date = EndOfDay(Parameters.Date);
					NewDocumentChangingFASettings.Organization = Parameters.Organization;
					NewDocumentChangingFASettings.PostInAccounting = ReflectVBAForLine;
					NewDocumentChangingFASettings.FixedAssetsEvent = Parameters.Event;
					NewDocumentChangingFASettings.RecordInManAccounting = ReflectVueForString;
					NewDocumentChangingFASettings.RecordInLocalAccounting = ReflectVBAForLine;
					NewDocumentChangingFASettings.EmployeeResponsible = Users.CurrentUser();
					NewDocumentChangingFASettings.Comment =
						NStr("vi = 'Chứng từ được lập tự động khi thay đổi phần tử khấu hao theo nhóm';
							|ru = 'Документ сформирован автоматически при групповом изменении элементов амортизации';
							|en = 'The document is generated automatically upon bulk modification of depreciation items'; fa = 'The document is generated automatically upon bulk modification of depreciation items';
							|it = 'Documento creato automaticamente durante la modifica di gruppo degli elementi di ammortamento';
							|pl = 'Dokument został wygenerowany automatycznie przy grupowej zmianie elementów amortyzacji';
							|tr = 'Amortisman öğelerini toplu olarak değiştirdiğinizde belge otomatik olarak oluşturulur'");
					
					Page1 = NewDocumentChangingFASettings.FA.Add();
					Page1.FixedAsset = String.FixedAsset;
					
					If ValueIsFilled(String.UsefulLifeAccounting) Then
						NewDocumentChangingFASettings.UsefulLifeAccountingFlag = True;
						NewDocumentChangingFASettings.UsefulLifeAccounting = String.UsefulLifeAccounting;
						NewDocumentChangingFASettings.SpecifiedRemainingUsefulLifeAC = True;
					EndIf;
					
					If ValueIsFilled(String.UsefulLifeManagementAccounting) Then
						NewDocumentChangingFASettings.UsefulLifeManagementAccountingFlag = True;
						NewDocumentChangingFASettings.UsefulLifeManagementAccounting = String.UsefulLifeManagementAccounting;
						NewDocumentChangingFASettings.SpecifiedRemainingUsefulLifeMA = True;
					EndIf;
					
					If ValueIsFilled(String.EstimatedRunningTime) Then
						NewDocumentChangingFASettings.EstimatedRunningTimeFlag = True;
						NewDocumentChangingFASettings.EstimatedRunningTime = String.EstimatedRunningTime;
					EndIf;
					
					If ValueIsFilled(String.ResidualValueLocal) Then
						NewDocumentChangingFASettings.ResidualValueLocalFlag = True;
						NewDocumentChangingFASettings.ResidualValueLocal = String.ResidualValueLocal;
					EndIf;
					
					If ValueIsFilled(String.ResidualValueMan) Then
						NewDocumentChangingFASettings.ResidualValueManFlag = True;
						NewDocumentChangingFASettings.ResidualValueMan = String.ResidualValueMan;
					EndIf;
					
					NewDocumentChangingFASettings.Write(DocumentWriteMode.Posting);
					
					If Parameters.AdjustAccumulatedDepreciation Then
						// Creating a document for correcting the cost and mortisation of the
						NewCostAdjustmentDocument = Documents.FixedAssetCostAndDepreciationAdjustment.CreateDocument();
						NewCostAdjustmentDocument.Date = EndOfDay(Parameters.Date);
						NewCostAdjustmentDocument.Organization = Parameters.Organization;
						NewCostAdjustmentDocument.RecordInLocalAccounting = NewDocumentChangingFASettings.RecordInLocalAccounting;
						NewCostAdjustmentDocument.RecordInManAccounting = NewDocumentChangingFASettings.RecordInManAccounting;
						NewCostAdjustmentDocument.Comment =
							NStr("vi = 'Chứng từ được lập tự động khi thay đổi phần tử khấu hao theo nhóm';
								|ru = 'Документ сформирован автоматически при групповом изменении элементов амортизации';
								|en = 'The document is generated automatically upon bulk modification of depreciation items'; fa = 'The document is generated automatically upon bulk modification of depreciation items';
								|it = 'Documento creato automaticamente durante la modifica di gruppo degli elementi di ammortamento';
								|pl = 'Dokument został wygenerowany automatycznie przy grupowej zmianie elementów amortyzacji';
								|tr = 'Amortisman öğelerini toplu olarak değiştirdiğinizde belge otomatik olarak oluşturulur'");
						NewCostAdjustmentDocument.Department = String.Department;
						NewCostAdjustmentDocument.FixedAssetsEvent = Parameters.Event;
						NewCostAdjustmentDocument.IncomeLiabilityItemCostIncrease = Parameters.IncomeItem;
						NewCostAdjustmentDocument.DimensionCostIncrease = Parameters.DimensionOfRevenue;
						NewCostAdjustmentDocument.AssetsLiabilitiesIncomeDimensionCostIncrease = Parameters.AssetsLiabilitiesIncomeDimension;
						NewCostAdjustmentDocument.AssetExpenseItemCostReduction = Parameters.ExpenseItem;
						NewCostAdjustmentDocument.DimensionOfExpensesCostReduction = Parameters.DimensionOfExpenses;
						NewCostAdjustmentDocument.DimensionCostDecrease = Parameters.AssetsLiabilitiesDimension;
						NewCostAdjustmentDocument.ExpenseLedgerAccountsSettingsCostDecrease = Parameters.GLAccountSettings;
						NewCostAdjustmentDocument.IncomeLedgerAccountsSettingsCostIncrease = Parameters.IncomeLedgerAccountsSettings;
						NewCostAdjustmentDocument.PeriodAdjustment = ?(Parameters.AdjustmentDueToChangeOfAccountingPolicy,
							LocalAccntingClientServer.MainValueOfClarifyingInterReportingPeriod(), 0);
						NewCostAdjustmentDocument.Fill(NewDocumentChangingFASettings.Ref);
						
						NewCostAdjustmentDocument.Write(DocumentWriteMode.Posting);
					EndIf;
					
					CommitTransaction();
				Except
					RollbackTransaction();
					MessageText = StrTemplate(NStr("vi = 'Không thể tạo chứng từ do nguyên nhân: %1';
													|ru = 'Не удалось создать документы по причине: %1';
													|en = 'Cannot create documents due to: %1'; fa = 'Cannot create documents due to: %1';
													|it = 'Non è stato possibile creare documenti a causa di: %1';
													|pl = 'Nie udało się utworzyć dokumentów z powodu: %1';
													|tr = 'Belge şu sebeple oluşturulamadı:%1'"),
						DetailErrorDescription(ErrorInfo()));
					WriteLogEvent(
						InfobaseUpdate.EventLogEvent(), 
						EventLogLevel.Warning, 
						, 
						, 
						MessageText);
				EndTry;
			EndIf;
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
	EndTry;
	
EndProcedure

#EndRegion

#EndIf