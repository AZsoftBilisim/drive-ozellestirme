
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
		
	SetConditionalAppearance();
	
	Date = EndOfYear(CurrentSessionDate());
	
	ItemsAndDimensionsSelectionParameters = DataProcessors.BulkEditOfDepreciationItems.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	SetupParameters = DataProcessors.BulkEditOfDepreciationItems.AccountingAccountSettings_();
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	
	ConfigureDependentFormElementsOnServer();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfChangeOnServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure IncomeItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure IncomeItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PresentationOfRecordingInComplAccountingClick(Item, StandardProcessing)
	
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PresentationOfTheIncomeReflectionInTheReglAccountingClick(Item, StandardProcessing)
	
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PostInAccountingOnChange(Item)
	
	Items.AdjustmentDueToChangeOfAccountingPolicy.Enabled = PostInAccounting;
	Items.AdjustAccumulatedDepreciation.Enabled = PostInAccounting;
	Items.FixedAssetsBUState.Visible = PostInAccounting;
	Items.FixedAssetsUsefulLifeAccounting.Visible = PostInAccounting;
	Items.FixedAssetsResidualValueLocal.Visible = PostInAccounting;
	If Not PostInAccounting Then
		AdjustmentDueToChangeOfAccountingPolicy = False;
		AdjustAccumulatedDepreciation = False;
	EndIf;
	FillInCurParameterValues();
	
EndProcedure

&AtClient
Procedure RecordInMAOnChange(Item)
	
	Items.FixedAssetsStateOfTheUU.Visible = RecordInMA;
	Items.FixedAssetsUsefulLifeManagementAccounting.Visible = RecordInMA;
	Items.FixedAssetsResidualValueMan.Visible = RecordInMA;
	FillInCurParameterValues();
	
EndProcedure

&AtClient
Procedure AdjustmentDueToChangeOfAccountingPolicyOnChange(Item)
	
	If AdjustmentDueToChangeOfAccountingPolicy Then
		AdjustAccumulatedDepreciation = True;
		Items.AdjustAccumulatedDepreciation.Enabled = False;
	Else
		Items.AdjustAccumulatedDepreciation.Enabled = True;
	EndIf;
	FillInCurParameterValues();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFA

&AtClient
Procedure FixedAssetsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If NonCurrentAssetsClientServer.ProcessingElementSelection(Object.FixedAssets, "FixedAsset", ValueSelected).Count() <> 0 Then
		FillInCurParameterValues(False, ValueSelected);
	EndIf;
	
EndProcedure

&AtClient
Procedure FixedAssetsFixedAssetOnChange(Item)
	
	FillInCurParameterValues(False, Items.FixedAssets.CurrentData.FixedAsset);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure LoadFromFile(Command)
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "DataProcessor.BulkEditOfDepreciationItems.FixedAssets";
	ImportParameters.Title = NStr("vi = 'Kết nhập từ tệp';
									|ru = 'Загрузка из файла';
									|en = 'Import from file'; fa = 'ورود از فایل';
									|it = 'Download dal file';
									|pl = 'Pobranie z pliku';
									|tr = 'Dosyadan içe aktarma'");
	Notification = New CallbackDescription("LoadFromFileCompletion", ThisObject);
	ImportDataFromFileClient.ShowImportForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure LoadFromFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ImportedDataAddress = Undefined Then 
		Return;
	EndIf;
	
	UploadFromFileOnServer(ImportedDataAddress);
	
EndProcedure

&AtServer
Procedure UploadFromFileOnServer(ImportedDataAddress)
	
	ImportedData = GetFromTempStorage(ImportedDataAddress);
	
	FAAdded = False;
	For Each TableRow In ImportedData Do 
	
		If Not ValueIsFilled(TableRow.FixedAsset) Then 
			Continue;
		EndIf;
	
		NewLineProducts = Object.FixedAssets.Add();
		NewLineProducts.FixedAsset = TableRow.FixedAsset;
		NewLineProducts.UsefulLifeAccounting = TableRow.UsefulLifeAccounting;
		NewLineProducts.UsefulLifeManagementAccounting = TableRow.UsefulLifeManagementAccounting;
		NewLineProducts.EstimatedRunningTime = TableRow.EstimatedRunningTime;
		NewLineProducts.ResidualValueLocal = TableRow.ResidualValueLocal;
		NewLineProducts.ResidualValueMan = TableRow.ResidualValueMan;
		
		FAAdded = True;
	EndDo;
	
	If FAAdded Then
		Modified = True;
		FillInCurParameterValues();
	EndIf;

EndProcedure

&AtServer
Function CreateDocumentsInBackgroundOnServer()
	
	GLAccountSettingsServer.RecordFormSInvoiceSettings(ThisObject);
	
	FunctionParameters = New Structure;
	FunctionParameters.Insert("Organization", Object.Organization);
	FunctionParameters.Insert("IncomeItem", Object.IncomeItem);
	FunctionParameters.Insert("DimensionOfRevenue", Object.DimensionOfRevenue);
	FunctionParameters.Insert("ExpenseItem", Object.ExpenseItem);
	FunctionParameters.Insert("DimensionOfExpenses", Object.DimensionOfExpenses);
	FunctionParameters.Insert("AssetsLiabilitiesDimension", Object.AssetsLiabilitiesDimension);
	FunctionParameters.Insert("AssetsLiabilitiesIncomeDimension", Object.AssetsLiabilitiesIncomeDimension);
	FunctionParameters.Insert("GLAccountSettings", Object.GLAccountSettings);
	FunctionParameters.Insert("IncomeLedgerAccountsSettings", Object.IncomeLedgerAccountsSettings);
	FunctionParameters.Insert("PostInAccounting", PostInAccounting);
	FunctionParameters.Insert("RecordInMA", RecordInMA);
	FunctionParameters.Insert("Date", Date);
	FunctionParameters.Insert("Event", Event);
	FunctionParameters.Insert("AdjustmentDueToChangeOfAccountingPolicy", AdjustmentDueToChangeOfAccountingPolicy);
	FunctionParameters.Insert("AdjustAccumulatedDepreciation", AdjustAccumulatedDepreciation);
	FunctionParameters.Insert("FixedAssets", Object.FixedAssets.Unload());
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteProcedure(
		ExecutionParameters, "DataProcessors.BulkEditOfDepreciationItems.CreateDocumentsInBackgroundOnServer", FunctionParameters);
	
	Return TimeConsumingOperation;
	
EndFunction

&AtClient
Procedure CreateDocuments(Command)
	
	ClearMessages();
	If Not ValueIsFilled(Object.Organization)
		Or Not ValueIsFilled(Object.IncomeItem)
		Or Not ValueIsFilled(Object.ExpenseItem)
		Or Not ValueIsFilled(Date) Then
			MessageText = NStr("vi = 'Hãy điền các mục tin cần thiết';
								|ru = 'Заполните обязательные реквизиты';
								|en = 'Fill in required attributes'; fa = 'Fill in required attributes';
								|it = 'Compilare gli attributi necessari';
								|pl = 'Wypełnij wymagane atrybuty';
								|tr = 'Zorunlu öznitelikleri doldurun'");
			CommonClient.MessageToUser(MessageText);
			Return;
	ElsIf Not PostInAccounting And Not RecordInMA Then
		MessageText = NStr("vi = 'Hãy điền dấu hiệu phản ánh vào kế toán';
							|ru = 'Заполните признак отражения в учете';
							|en = 'Fill in the flag of recording in accounting'; fa = 'Fill in the flag of recording in accounting';
							|it = 'Compilare il segno di riflessione in contabilità';
							|pl = 'Wypełnij oznakę odzwierciedlenia w ewidencji';
							|tr = 'Muhasebedeki yansıma özniteliğini doldurun'");
		CommonClient.MessageToUser(MessageText);
		Return;
	Else
		CreateDocumentsInBackground();
	EndIf;
	
EndProcedure

&AtClient
Procedure Pick(Command)
	
	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.FixedAssetsFixedAsset, ThisObject);
	SelectionParameters_1 = New Structure;
	SelectionParameters_1.Insert("Buorganization", Object.Organization);
	PickingParameters.Insert("Filter", SelectionParameters_1);
	PickingParameters.Insert("DateOfLastEdit", Date);

	OpenForm("Catalog.Assets.ChoiceForm",
					PickingParameters, Items.FixedAssets,,,,,
					FormWindowOpeningMode.LockOwnerWindow)
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ConfigureDependentFormElementsOnServer(Val ChangedBankingDetails = "")
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then
		
		ReglVNAAccountingIsCarriedOutIndependentlySettingUp = AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Object.Organization, Date);
		
		If FALocalAccountingIsConductedIndependently <> ReglVNAAccountingIsCarriedOutIndependentlySettingUp Then
			
			FALocalAccountingIsConductedIndependently = ReglVNAAccountingIsCarriedOutIndependentlySettingUp;
			
			Items.PostInAccounting.Visible = FALocalAccountingIsConductedIndependently;
			Items.RecordInMA.Visible = FALocalAccountingIsConductedIndependently;
			
			If Not FALocalAccountingIsConductedIndependently Then
				PostInAccounting = True;
				RecordInMA = True;
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DateOfChangeOnServer()
	
	FillInCurParameterValues();
	
	ConfigureDependentFormElementsOnServer("Date");
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	FillInCurParameterValues();
	
	ConfigureDependentFormElementsOnServer("Organization");
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsLineNumber.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsFixedAsset.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsAssetID.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsOrganization.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsDepartment.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsBUState.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsStateOfTheUU.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsUsefulLifeAccounting.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsUsefulLifeManagementAccounting.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsEstimatedRunningTime.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsResidualValueLocal.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsResidualValueMan.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsCostAdjustmentDocument.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FixedAssets.CostAdjustmentDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("BackColor", StyleColors.AddedAttributeBackground);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsLineNumber.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsFixedAsset.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsAssetID.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsOrganization.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsDepartment.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsBUState.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsStateOfTheUU.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsUsefulLifeAccounting.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsUsefulLifeManagementAccounting.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsEstimatedRunningTime.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsResidualValueLocal.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsResidualValueMan.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsCostAdjustmentDocument.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FixedAssets.CostAdjustmentDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("BackColor", StyleColors.CreateRightBackground);
	
EndProcedure

&AtServer
Procedure FillInCurParameterValues(AdditionalInformationOnly = True, SelectedFixedAsset = Undefined)
	
	If Object.FixedAssets.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	
	Query.Text =
	"SELECT
	|	Assets.Ref                                         AS FixedAsset,
	|	Assets.Ref.AssetID                        AS AssetID,
	|	ISNULL(OSBUDepreciationParameters.UsefulLifeMonthsAC, 0) AS UsefulLifeAccounting,
	|	ISNULL(FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths, 0)            AS UsefulLifeManagementAccounting,
	|	ISNULL(FixedAssetsAccountingProcedure.EstimatedRunningTime, UNDEFINED)              AS EstimatedRunningTime,
	|	ISNULL(FixedAssetDepreciationParametersManagementAccounting.ResidualValueLocal, 0)  AS ResidualValueLocal,
	|	ISNULL(FixedAssetDepreciationParametersManagementAccounting.ResidualValueMan, 0)      AS ResidualValueMan,
	|	CASE
	|		WHEN AccountingProcedureForOSBU.BUState <> VALUE(Enum.FixedAssetsStates.EmptyRef)
	|			THEN AccountingProcedureForOSBU.BUState
	|		ELSE ISNULL(AccountingProcedureForOSBU.StateTa, VALUE(Enum.FixedAssetsStates.NotRecognized_))
	|	END                                                                                    AS BUState,
	|	ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.FixedAssetsStates.NotRecognized_)) AS StateOfTheUU,
	|	ISNULL(FALocation.Organization, VALUE(Catalog.Companies.EmptyRef))   AS Organization,
	|	ISNULL(FALocation.FixedAssetsLocation, VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
	|	ISNULL(FixedAssetCostAndDepreciationAdjustmentFA.Ref, ChangeFixedAssetFinancialDetails2_4.Ref)            AS CostAdjustmentDocument,
	|	ISNULL(CAST(DATEDIFF(BEGINOFPERIOD(FixedAssetDepreciationParametersManagementAccounting.LastChangeDate, MONTH), &Period, MONTH) AS NUMBER(20,8)),0) AS NumberOfMonthsAfterAcceptanceForAccountingBeforeDateInProcessingMA,
	|	ISNULL(CAST(DATEDIFF(BEGINOFPERIOD(OSBUDepreciationParameters.LastChangeDate, MONTH), &Period, MONTH) AS NUMBER(20,8)),0) AS NumberOfMonthsAfterAcceptanceForAccountingBeforeDateInProcessingAC
	|FROM
	|	Catalog.Assets AS Assets
	|		LEFT JOIN InformationRegister.FixedAssetDepreciationParametersManagementAccounting.SliceLast(
	|			&Period,
	|			Organization = &Organization
	|				AND FixedAsset IN (&ListOfFA)) AS FixedAssetDepreciationParametersManagementAccounting
	|		ON (FixedAssetDepreciationParametersManagementAccounting.FixedAsset = Assets.Ref)
	|		LEFT JOIN InformationRegister.OSBUDepreciationParameters.SliceLast(
	|			&Period,
	|			Organization = &Organization
	|				AND FixedAsset IN (&ListOfFA)) AS OSBUDepreciationParameters
	|		ON (OSBUDepreciationParameters.FixedAsset = Assets.Ref)
	|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedure.SliceLast(
	|			&Period,
	|			Organization = &Organization
	|				AND FixedAsset IN (&ListOfFA)) AS FixedAssetsAccountingProcedure
	|		ON (FixedAssetsAccountingProcedure.FixedAsset = Assets.Ref)
	|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
	|			&Period,
	|			Organization = &Organization
	|				AND FixedAsset IN (&ListOfFA)) AS FixedAssetsAccountingProcedureManagementAccounting
	|		ON (FixedAssetsAccountingProcedureManagementAccounting.FixedAsset = Assets.Ref)
	|		LEFT JOIN InformationRegister.AccountingProcedureForOSBU.SliceLast(
	|			&Period,
	|			Organization = &Organization
	|				AND FixedAsset IN (&ListOfFA)) AS AccountingProcedureForOSBU
	|		ON (AccountingProcedureForOSBU.FixedAsset = Assets.Ref)
	|		LEFT JOIN InformationRegister.FALocation.SliceLast(
	|			&Period,
	|			Organization = &Organization
	|				AND FixedAsset IN (&ListOfFA)) AS FALocation
	|		ON (FALocation.FixedAsset = Assets.Ref)
	|		LEFT JOIN Document.FixedAssetCostAndDepreciationAdjustment.FA AS FixedAssetCostAndDepreciationAdjustmentFA
	|		ON (FixedAssetCostAndDepreciationAdjustmentFA.FixedAsset = Assets.Ref)
	|			AND (FixedAssetCostAndDepreciationAdjustmentFA.Ref.Posted)
	|			AND (&PostInAccounting = FixedAssetCostAndDepreciationAdjustmentFA.Ref.RecordInLocalAccounting)
	|			AND (&RecordInMA = FixedAssetCostAndDepreciationAdjustmentFA.Ref.RecordInManAccounting)
	|			AND (&AdjustmentDueToChangeOfAccountingPolicy = FixedAssetCostAndDepreciationAdjustmentFA.Ref.PeriodAdjustment <> 0)
	|			AND (&Period = FixedAssetCostAndDepreciationAdjustmentFA.Ref.Date)
	|		LEFT JOIN Document.ChangeFixedAssetFinancialDetails2_4.FA AS ChangeFixedAssetFinancialDetails2_4
	|		ON (ChangeFixedAssetFinancialDetails2_4.FixedAsset = Assets.Ref)
	|			AND (ChangeFixedAssetFinancialDetails2_4.Ref.Posted)
	|			AND (&PostInAccounting = ChangeFixedAssetFinancialDetails2_4.Ref.RecordInLocalAccounting)
	|			AND (&RecordInMA = ChangeFixedAssetFinancialDetails2_4.Ref.RecordInManAccounting)
	|			AND (&Period = ChangeFixedAssetFinancialDetails2_4.Ref.Date)
	|WHERE
	|	Assets.Ref IN(&ListOfFA)";
	
	Query.SetParameter("Organization", Object.Organization);
	
	If SelectedFixedAsset = Undefined Then
		Query.SetParameter("ListOfFA", Object.FixedAssets.Unload().UnloadColumn("FixedAsset"));
	Else
		Query.SetParameter("ListOfFA", SelectedFixedAsset);
	EndIf;
	
	Query.SetParameter("Period", EndOfDay(?(ValueIsFilled(Date), Date, CurrentSessionDate())));
	Query.SetParameter("PostInAccounting", PostInAccounting);
	Query.SetParameter("RecordInMA", RecordInMA);
	Query.SetParameter("AdjustmentDueToChangeOfAccountingPolicy", AdjustmentDueToChangeOfAccountingPolicy);
	
	SetPrivilegedMode(True);
	Result = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	For Each RowData In Object.FixedAssets Do
		CurrentValues = Result.Find(RowData.FixedAsset, "FixedAsset");
		If CurrentValues <> Undefined Then
			If AdditionalInformationOnly Then
				RowData.AssetID = CurrentValues.AssetID;
				RowData.BUState = CurrentValues.BUState;
				RowData.StateOfTheUU = CurrentValues.StateOfTheUU;
				RowData.Organization = CurrentValues.Organization;
				RowData.Department = CurrentValues.Department;
				RowData.CostAdjustmentDocument = CurrentValues.CostAdjustmentDocument;
			Else
				FillPropertyValues(RowData, CurrentValues);
				If CurrentValues.UsefulLifeAccounting - CurrentValues.NumberOfMonthsAfterAcceptanceForAccountingBeforeDateInProcessingAC > 0
					And (CurrentValues.BUState = Enums.FixedAssetsStates.Recognized_
						Or CurrentValues.BUState = Enums.FixedAssetsStates.InLease
						Or CurrentValues.BUState = Enums.FixedAssetsStates.LeasedOut) Then
							RowData.UsefulLifeAccounting = CurrentValues.UsefulLifeAccounting
												- CurrentValues.NumberOfMonthsAfterAcceptanceForAccountingBeforeDateInProcessingAC;
				Else
					RowData.UsefulLifeAccounting = 0;
				EndIf;
				If CurrentValues.UsefulLifeManagementAccounting - CurrentValues.NumberOfMonthsAfterAcceptanceForAccountingBeforeDateInProcessingMA > 0
					And (CurrentValues.StateOfTheUU = Enums.FixedAssetsStates.Recognized_
						Or CurrentValues.StateOfTheUU = Enums.FixedAssetsStates.InLease
						Or CurrentValues.StateOfTheUU = Enums.FixedAssetsStates.LeasedOut) Then
							RowData.UsefulLifeManagementAccounting = CurrentValues.UsefulLifeManagementAccounting
											- CurrentValues.NumberOfMonthsAfterAcceptanceForAccountingBeforeDateInProcessingMA;
				Else
					RowData.UsefulLifeManagementAccounting = 0;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure CreateDocumentsInBackground()
	
	TimeConsumingOperation = CreateDocumentsInBackgroundOnServer();
	
	CallbackOnCompletion = New CallbackDescription("CreatingDocumentsInBackgroundCompletion", ThisObject);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = True;
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure 

&AtClient
Procedure CreatingDocumentsInBackgroundCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then // The user canceled the task.
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		MessageText = Result.BriefErrorDescription;
		ShowMessageBox(,NStr("vi = 'Chứng từ không được tạo mới do nguyên nhân:';
							|ru = 'Документы не были созданы по причине:';
							|en = 'Documents were not created due to:'; fa = 'Documents were not created due to:';
							|it = 'I documenti non sono stati creati a causa di:';
							|pl = 'Dokumenty nie były utworzone z powodu:';
							|tr = 'Belgeler şu nedenlerden dolayı oluşturulmamıştır:'") + Chars.LF + MessageText);
	Else
		FillInCurParameterValues();
	EndIf;
	
EndProcedure
	
#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_F_Date" Then
		DateOnChange(Items.Date);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
