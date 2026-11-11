////////////////////////////////////////////////////////////////////////////////
// Procedures of the subsystem "Non-current assets".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region FAAccounting

// Adds parameter values to reflect the write-off of the asset.
// 
// Parameters:
// 	ValuesOfHoldingParameters - Structure - 
Procedure AddValuesOfPaymentParametersWhenDebitingFA(ValuesOfHoldingParameters) Export

	ValuesOfHoldingParameters.Insert("BO_WriteOffFixedAssetsCost", Enums.BusinessTransactions.WriteOffFixedAssetsCost);
	ValuesOfHoldingParameters.Insert("ConfiguringHO_ChargingCostOfFA", Catalogs.BusinessTransactionsSettings.WriteOffFixedAssetsCost);

	ValuesOfHoldingParameters.Insert("BO_FixedAssetDepreciationWriteOff", Enums.BusinessTransactions.FixedAssetDepreciationWriteOff);
	ValuesOfHoldingParameters.Insert("ConfiguringHO_WriteOffFADepreciation", Catalogs.BusinessTransactionsSettings.FixedAssetDepreciationWriteOff);

	ValuesOfHoldingParameters.Insert("BO_WriteOffRevaluationReserveOfFixedAssetsCost", Enums.BusinessTransactions.WriteOffRevaluationReserveOfFixedAssetsCost);
	ValuesOfHoldingParameters.Insert("ConfiguringHO_WriteOffOfFARevaluationReserve", Catalogs.BusinessTransactionsSettings.WriteOffRevaluationReserveOfFixedAssetsCost);

	ValuesOfHoldingParameters.Insert("BO_WriteOffRevaluationReserveOfFixedAssetDepreciation", Enums.BusinessTransactions.WriteOffRevaluationReserveOfFixedAssetDepreciation);
	ValuesOfHoldingParameters.Insert("SettingUpHO_WriteOffOfFADepreciationRevaluationReserve", Catalogs.BusinessTransactionsSettings.WriteOffRevaluationReserveOfFixedAssetDepreciation);
	
	ValuesOfHoldingParameters.Insert("ArticleAP_OS", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets);
	ValuesOfHoldingParameters.Insert("ArticleAP_AccountingObject", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets);
	ValuesOfHoldingParameters.Insert("Article6_ProfitLoss", ChartsOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss);
	
	ValuesOfHoldingParameters.Insert("BO_CloseFixedAssetWriteOffExpenses", Enums.BusinessTransactions.CloseFixedAssetWriteOffExpenses);
	ValuesOfHoldingParameters.Insert("SettingUpHO_ClosingExpensesFromFADebiting", Catalogs.BusinessTransactionsSettings.CloseFixedAssetWriteOffExpenses);

	ValuesOfHoldingParameters.Insert("BO_CloseFixedAssetSalesExpenses", Enums.BusinessTransactions.CloseFixedAssetSalesExpenses);
	ValuesOfHoldingParameters.Insert("SettingUpHO_ClosingExpensesFromFAImplementation", Catalogs.BusinessTransactionsSettings.CloseFixedAssetSalesExpenses);

	ValuesOfHoldingParameters.Insert("BO_WriteOffOfFAImpairment", Enums.BusinessTransactions.WriteOffOfFAImpairment);
	ValuesOfHoldingParameters.Insert("SettingUpHO_WriteOffOfFAImpairment", Catalogs.BusinessTransactionsSettings.WriteOffOfFAImpairment);
	
EndProcedure

// Get the nodes for the FA list.
// 
// Parameters:
//  ListOfFA - ValueList - FA list.
//  Period - Date
// 
// Returns:
//  QueryResultSelection - Get FA Nodes
Function GetFANodes(ListOfFA, Period) Export

	Query = New Query;
	Query.SetParameter("ListOfFA", ListOfFA);
	Query.SetParameter("Period", Period);
	Query.Text = "SELECT
	               |	SubAssetsComponentsOfDepreciationSliceLast.SubAssetComponent AS FixedAsset
	               |FROM
	               |	InformationRegister.SubAssetsComponentsOfDepreciation.SliceLast(&Period, ) AS SubAssetsComponentsOfDepreciationSliceLast
	               |WHERE
	               |	SubAssetsComponentsOfDepreciationSliceLast.FixedAsset IN(&ListOfFA)";

	Return Query.Execute().Select();
	
EndFunction

// Determines the presence of nodes.
// 
// Parameters:
//  ListOfFA - Array of CatalogRef.Assets - FA list.
//  Ref - DocumentRef - Document.
//  Period - Date - date.
// 
// Returns:
//  Boolean - True if there are nodes
Function ThereAreNodes(ListOfFA, Ref, Period) Export

	QueryText =
	"SELECT TOP 1
	|	RegisterData.SubAssetComponent AS FixedAsset
	|FROM
	|	InformationRegister.SubAssetsComponentsOfDepreciation.SliceLast(&Period, Recorder <> &Ref) AS RegisterData
	|WHERE
	|	RegisterData.FixedAsset IN(&ListOfFA)
	|	AND RegisterData.SubAssetComponent.OSType = VALUE(Enum.FATypes.Node)";

	Query = New Query(QueryText);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Period", Period);
	Query.SetParameter("ListOfFA", ListOfFA);

	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion

#Region JobsForMonthEndClosing

// Generates entries in the task registers by the end of the month.
// 
// Parameters:
// 	Document - DocumentObject -
// 	TablesData - See DocumentsPosting.OldStructureTableData
Procedure GenerateTaskRegisterEntries(Document, TablesData) Export

	If Not GetFunctionalOption("UseNonCurrentAssets2_2")
			And Not GetFunctionalOption("UseNonCurrentAssets2_4")
		Or ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("NonCurrentAssets.CreatingTasksForEndOfMonth");
	
	TempTablesManager = TablesData.TempTablesManager;
	
	FixedAssetDepreciationCalculation.GenerateJobs(Document, TablesData);
	IntangibleAssetAmortizationCalculation.GenerateJobs(Document, TablesData);
	FACostCalculation.GenerateJobs(Document, TablesData);
	DeferredFARecordGeneration.GenerateJobs(Document, TablesData);
	ClosingExpensesFromDisposalOfFixedAssets.GenerateJobs(Document, TempTablesManager);
	ImpairmentFAServer.CreateTasksForEndOfMonthUsingOSNMA(Document, TablesData);
	CalculateRentalInvestmentCost.GenerateJobs(Document, TempTablesManager);
		
	LeasedAssetAccounting.GenerateTaskRegisterEntries(Document, TablesData);
	NonCurrentAssetsLocalization.GenerateTaskRegisterEntries(Document, TablesData);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, 1);
	
EndProcedure

// Generates tasks when recording the movements of the distribution of settlements.
//
// Parameters:
//  TempTablesManager	 - TempTablesManager		 - temporary table manager.
//
Procedure CreateTasksWhenRecordingRegisteredRecordsAndPayments(TempTablesManager) Export
	
	NonCurrentAssetsLocalization.CreateTasksWhenRecordingRegisteredRecordsAndPayments(TempTablesManager);
	
EndProcedure

#EndRegion

#Region Print

// ID of the print warning.
// It is used to display the text of the message to the user in the form of a warning in the header of the "Print documents" form.
//
// Returns:
//   String - The Value of the Attribute field of the message object to the user.
//       In the Attributes, the text of the message object to the user can be either a regular test
//       or a formatted string template (See StringFunctions.FormattedString)
//            .
Function IDOfPrintWarning() Export
	Return "WarningInformationIsIrrelevant";
EndFunction

// Adds a warning text informing the user that the cost or depreciation is not relevant
// because the closing of the month has not been completed.
// 
// Parameters:
//  InformationRelevant - Boolean - False if the information is not relevant.
//  Tabular Document - Tabular Document - Printed form
Procedure AddWarningIfInformationIsNotUpToDate(InformationRelevant) Export

	If InformationRelevant Then
		Return;
	EndIf;
	
	// The information that the information is irrelevant is transmitted to the print form through messages to the user.
	IrrelevantMessage = New UserMessage;
	IrrelevantMessage.Field = IDOfPrintWarning();
	IrrelevantMessage.Text = NStr(
		"vi = 'Chưa cập nhật giá trị và khấu hao, cần thực hiện đóng tháng.';
		|ru = 'Стоимость и амортизация не актуальны, необходимо выполнить закрытие месяца.';
		|en = 'Cost and depreciation are not relevant, close the month.'; fa = 'Cost and depreciation are not relevant, close the month.';
		|it = 'Costo e ammortamento non aggiornati, è necessario effettuare la chiusura nel mese.';
		|pl = 'Wartość i amortyzacja nie są aktualne, należy wykonać zamknięcie miesiąca.';
		|tr = 'Maliyet ve amortisman güncel değil, ay sonu kapanışı yapılmalı.'");
	IrrelevantMessage.Message();
	
EndProcedure

// See PrintManagementOverridable.PrintDocumentsOnCreateAtServer.
Procedure PrintDocumentsOnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	// Warnings of printed forms are displayed via messages to the user.
	Messages = GetUserMessages(True);
	WarningID = IDOfPrintWarning();
	For Each Message In Messages Do
		
		// Warnings that require output to the header are marked with a special field name.
		If Message.Field <> WarningID Then
			// When messages are received, they are cleared. 
			// If there were messages in the message queue that were not related to the printed form messages for VNA, they will disappear.
			// Let's restore these messages.
			Message.Message();
			Continue;
		EndIf;
		
		// There may be several warnings, so before creating elements, a free name is selected.
		NumberOfSuffix = 0;
		Suffix = WarningID;
		While Form.Items.Find(Suffix + Format(NumberOfSuffix, "NG=")) <> Undefined Do
			NumberOfSuffix = NumberOfSuffix + 1;
		EndDo;
		If NumberOfSuffix <> 0 Then
			Suffix = Suffix + Format(NumberOfSuffix, "NG=");
		EndIf;
		
		// If the text is voluminous (detailed), then a short part is highlighted from it.
		Position = StrFind(Message.Text, Chars.LF, , , 2);
		If Position > 0 Then
			Brief1 = TrimAll(Left(Message.Text, Position - 1));
			More = Message.Text;
		Else
			Brief1 = Message.Text;
			More = "";
		EndIf;
		
		// Horizontal group.
		Group = Form.Items.Insert("Group" + Suffix, Type("FormGroup"), ,
			Form.Items.AdditionalInformationGroup);
		Group.Type = FormGroupType.UsualGroup;
		Group.ShowTitle = False;
		Group.Group = ChildFormItemsGroup.AlwaysHorizontal;
		
		// An exclamation mark of medium size.
		Picture = Form.Items.Add("Picture" + Suffix, Type("FormDecoration"), Group);
		Picture.Type = FormDecorationType.Picture;
		Picture.Picture = PictureLib.Warning32;
		
		// A short text of the warning.
		Label = Form.Items.Add(Suffix, Type("FormDecoration"), Group);
		Label.Type = FormDecorationType.Label;
		Label.Title = StringFunctions.FormattedString(Brief1);
		Label.AutoMaxWidth = False;
		Label.SetAction("URLProcessing", "Attachable_URLProcessing");

		If More <> "" Then
			// Hyperlink "More details...".
			GroupDetails_3 = Form.Items.Add("GroupDetails_3" + Suffix, Type("FormGroup"), Group);
			GroupDetails_3.Type = FormGroupType.UsualGroup;
			GroupDetails_3.Representation = UsualGroupRepresentation.None;
			GroupDetails_3.ShowTitle = True;
			GroupDetails_3.Title = NStr("vi = 'Chi tiết...';
										|ru = 'Подробнее...';
										|en = 'More...'; fa = 'More...';
										|it = 'Dettagliatamente...';
										|pl = 'More...';
										|tr = 'Ayrıntılar...'");
			GroupDetails_3.TitleTextColor = StyleColors.HyperlinkColor;
			GroupDetails_3.Group = ChildFormItemsGroup.AlwaysHorizontal;
			GroupDetails_3.Behavior = UsualGroupBehavior.PopUp;

			GroupDetails_3.VerticalAlignInGroup = ItemVerticalAlign.Bottom;
			
			// The detailed text of the warning.
			Label = Form.Items.Add("MoreDetails" + Suffix, Type("FormDecoration"), GroupDetails_3);
			Label.Type = FormDecorationType.Label;
			Label.Title = StringFunctions.FormattedString(More);
			Label.AutoMaxWidth = False;
			Label.SetAction("URLProcessing", "Attachable_URLProcessing");
		EndIf;

		Message.Text = ""; // Processed messages are forcibly cleared.

	EndDo;

EndProcedure

#EndRegion

#Region StandardMechanisms

// Defines a list of configuration objects, in the modules of managers of which the procedure is provided 
// Add a creation command on the basis that forms creation commands based on objects.
// For the syntax of the Add Command Creation procedure, see the documentation.
//
// Parameters:
//   Objects - Array - metadata objects (metadata Objects) with commands to create based on.
//
// Example:
//	Objects.Add (Metadata.Guides.Companies);
//   
Procedure OnDefineObjectsWithCreationBasedOnCommands(Objects) Export

	Objects.Add(Metadata.Documents.IntangibleAssetsAmortizationCharge2_4);
	Objects.Add(Metadata.Documents.FixedAssetsDepreciationCharge2_4);
	Objects.Add(Metadata.Documents.EntryOfCapitalAssetsBalance2_4);
	Objects.Add(Metadata.Documents.OBEntrySubAssetsAndComponentsOfDepreciation);
	Objects.Add(Metadata.Documents.ReturnAssetsFromLeasee2_4);
	Objects.Add(Metadata.Documents.ReturnLeasedAssets);
	Objects.Add(Metadata.Documents.IntangibleAssetsOperatingTime);
	Objects.Add(Metadata.Documents.SigningOfLeaseContract);
	Objects.Add(Metadata.Documents.ChangeIntangibleAssetFinancialDetails2_4);
	Objects.Add(Metadata.Documents.ChangeFixedAssetFinancialDetails2_4);
	Objects.Add(Metadata.Documents.LeaseTermAdjustment);
	Objects.Add(Metadata.Documents.IntangibleAssetsPhysicalCount);
	Objects.Add(Metadata.Documents.FixedAssetsPhysicalCount);
	Objects.Add(Metadata.Documents.IntangibleAssetsCostAndAmortizationAdjustment);
	Objects.Add(Metadata.Documents.FixedAssetCostAndDepreciationAdjustment);
	Objects.Add(Metadata.Documents.FixedAssetsCostAdditions2_4);
	Objects.Add(Metadata.Documents.MergeOfFixedAssets);
	Objects.Add(Metadata.Documents.AllocateVariancesToFixedAssetCost);
	Objects.Add(Metadata.Documents.ProvideAssetsToLeasee2_4);
	Objects.Add(Metadata.Documents.IATransfer2_4);
	Objects.Add(Metadata.Documents.FATransfer2_4);
	Objects.Add(Metadata.Documents.FARevaluation2_4);
	Objects.Add(Metadata.Documents.PreparingForIntangibleAssetSale2_4);
	Objects.Add(Metadata.Documents.PreparingForFixedAssetSale2_4);
	Objects.Add(Metadata.Documents.ReceiveLeasedAssets);
	Objects.Add(Metadata.Documents.ReceivingLeaseServices);
	Objects.Add(Metadata.Documents.IntangibleAssetsInitialRecognition2_4);
	Objects.Add(Metadata.Documents.FixedAssetsInitialRecognition2_4);
	Objects.Add(Metadata.Documents.RecognizeSubAssetsComponentsOfDepreciation);
	Objects.Add(Metadata.Documents.SplitFixedAssets);
	Objects.Add(Metadata.Documents.DisposeIntangibleAssets2_4);
	Objects.Add(Metadata.Documents.DisposeFixedAssets2_4);
	Objects.Add(Metadata.Documents.IntangibleAssetImprovement);
	
	Objects.Add(Metadata.Catalogs.LeaseContract);
	Objects.Add(Metadata.Catalogs.IntangibleAssets);
	Objects.Add(Metadata.Catalogs.Assets);
	Objects.Add(Metadata.Catalogs.ConstructionObjects);
	Objects.Add(Metadata.Catalogs.RDTopicsStages);
	
	NonCurrentAssetsLocalization.OnDefineObjectsWithCreationBasedOnCommands(Objects);
	
EndProcedure

// See PeriodClosingDatesOverridable.FillDataSourcesForPeriodClosingCheck
//
Procedure FillDataSourcesForPeriodClosingCheck(DataSources) Export
	
	Sections = New Map;
	Sections.Insert("ReceivingLeaseServices", "Purchases");
	Sections.Insert("AssetActivityRecord", "RMManagement");
	DocumentsList = ListOfVNADocuments();
	DocumentsList.Add("AssetActivityRecord");
	
	For Each DocumentName In DocumentsList Do
		
		Section = Sections.Get(DocumentName);
		If Section = Undefined Then
			Section = "NonCurrentAssets";
		EndIf;
		
		PeriodClosingDates.AddRow(DataSources, "Document." + DocumentName, "Date", Section, "Organization");
			
	EndDo;
	
	InformationRegisters.JobsForCalculatingFixedAssetDepreciation.DescriptionOfRegistersForControlOfDatesOfProhibitionOfChange(DataSources);
	InformationRegisters.JobsForCalculatingIntangibleAssetAmortization.DescriptionOfRegistersForControlOfDatesOfProhibitionOfChange(DataSources);
	InformationRegisters.JobsForCalculatingNonCurrentAssetCost.DescriptionOfRegistersForControlOfDatesOfProhibitionOfChange(DataSources);
	InformationRegisters.JobsForGeneratingFixedAssetRecords.DescriptionOfRegistersForControlOfDatesOfProhibitionOfChange(DataSources);
	InformationRegisters.JobsForUpdatingFixedAssetRecords.DescriptionOfRegistersForControlOfDatesOfProhibitionOfChange(DataSources);
	
	NonCurrentAssetsLocalization.FillDataSourcesForPeriodClosingCheck(DataSources);
	
EndProcedure

// See FilesOperationsOverridable.OnDefineFileStorageCatalogs
//
Procedure OnDefineFileStorageCatalogs(TypeFileOwner, CatalogNames) Export
	
	If TypeFileOwner = Type("DocumentRef.IntangibleAssetsAmortizationCharge2_4")
		Or TypeFileOwner = Type("DocumentRef.FixedAssetsDepreciationCharge2_4")
		Or TypeFileOwner = Type("DocumentRef.OBEntryOfLeaseSettlements")
		Or TypeFileOwner = Type("DocumentRef.EntryOfCapitalAssetsBalance2_4")
		Or TypeFileOwner = Type("DocumentRef.EnterRentalInvestmentBalance")
		Or TypeFileOwner = Type("DocumentRef.OBEntrySubAssetsAndComponentsOfDepreciation")
		Or TypeFileOwner = Type("DocumentRef.ReturnAssetsFromLeasee2_4")
		Or TypeFileOwner = Type("DocumentRef.ReturnLeasedAssets")
		Or TypeFileOwner = Type("DocumentRef.VendorInvoiceLeasedAssets")
		Or TypeFileOwner = Type("DocumentRef.IntangibleAssetsOperatingTime")
		Or TypeFileOwner = Type("DocumentRef.SigningOfLeaseContract")
		Or TypeFileOwner = Type("DocumentRef.ChangeIntangibleAssetFinancialDetails2_4")
		Or TypeFileOwner = Type("DocumentRef.ChangeFixedAssetFinancialDetails2_4")
		Or TypeFileOwner = Type("DocumentRef.LeaseTermAdjustment")
		Or TypeFileOwner = Type("DocumentRef.ChangeRentalTerms")
		Or TypeFileOwner = Type("DocumentRef.IntangibleAssetsPhysicalCount")
		Or TypeFileOwner = Type("DocumentRef.FixedAssetsPhysicalCount")
		Or TypeFileOwner = Type("DocumentRef.IntangibleAssetsCostAndAmortizationAdjustment")
		Or TypeFileOwner = Type("DocumentRef.FixedAssetCostAndDepreciationAdjustment")
		Or TypeFileOwner = Type("DocumentRef.FixedAssetsCostAdditions2_4")
		Or TypeFileOwner = Type("DocumentRef.AssetActivityRecord")
		Or TypeFileOwner = Type("DocumentRef.ImpairmentFA")
		Or TypeFileOwner = Type("DocumentRef.MergeOfFixedAssets")
		Or TypeFileOwner = Type("DocumentRef.AllocateVariancesToFixedAssetCost")
		Or TypeFileOwner = Type("DocumentRef.ProvideAssetsToLeasee2_4")
		Or TypeFileOwner = Type("DocumentRef.IATransfer2_4")
		Or TypeFileOwner = Type("DocumentRef.FATransfer2_4")
		Or TypeFileOwner = Type("DocumentRef.IARevaluation2_4")
		Or TypeFileOwner = Type("DocumentRef.FARevaluation2_4")
		Or TypeFileOwner = Type("DocumentRef.PreparingForIntangibleAssetSale2_4")
		Or TypeFileOwner = Type("DocumentRef.PreparingForFixedAssetSale2_4")
		Or TypeFileOwner = Type("DocumentRef.ReceiveLeasedAssets")
		Or TypeFileOwner = Type("DocumentRef.LeaseTermination")
		Or TypeFileOwner = Type("DocumentRef.RDExpenseRecognition")
		Or TypeFileOwner = Type("DocumentRef.IntangibleAssetsInitialRecognition2_4")
		Or TypeFileOwner = Type("DocumentRef.FixedAssetsInitialRecognition2_4")
		Or TypeFileOwner = Type("DocumentRef.RecognizeSubAssetsComponentsOfDepreciation")
		Or TypeFileOwner = Type("DocumentRef.SplitFixedAssets")
		Or TypeFileOwner = Type("DocumentRef.DisposeIntangibleAssets2_4")
		Or TypeFileOwner = Type("DocumentRef.DisposeFixedAssets2_4") 
		Or TypeFileOwner = Type("DocumentRef.IntangibleAssetImprovement")
		Or NonCurrentAssetsLocalization.DocumentHasAttachedFiles(TypeFileOwner) Then
		
		CatalogNames.Insert("DocumentsFAAttachedFiles", True);
	EndIf;
	
EndProcedure

// See AccessManagementOverridable.OnFillListsWithAccessRestriction
//
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	For Each DocumentName In ListOfVNADocuments() Do
		Lists.Insert(Metadata.Documents[DocumentName], True);
	EndDo;
	
	Lists.Insert(Metadata.AccumulationRegisters.IntangibleAssetsAmortizationCharge, True);
	Lists.Insert(Metadata.AccumulationRegisters.FixedAssetsDepreciationCharge, True);
	Lists.Insert(Metadata.AccumulationRegisters.InvestmentInRent, True);
	Lists.Insert(Metadata.AccumulationRegisters.IACost, True);
	Lists.Insert(Metadata.AccumulationRegisters.FACost, True);
	Lists.Insert(Metadata.InformationRegisters.IntangibleAssetsDocuments, True);
	Lists.Insert(Metadata.InformationRegisters.FixedAssetsDocuments, True);
	Lists.Insert(Metadata.InformationRegisters.FALocation, True);
	Lists.Insert(Metadata.InformationRegisters.IntangibleAssetsRegistrationPlace, True);
	Lists.Insert(Metadata.InformationRegisters.IADepreciationParametersBookkeepingAndTaxAccounting, True);
	Lists.Insert(Metadata.InformationRegisters.IADepreciationParametersBookkeepingAndTaxAccounting, True);
	Lists.Insert(Metadata.InformationRegisters.IntangibleAssetAmortizationParametersManagementAccounting, True);
	Lists.Insert(Metadata.InformationRegisters.OSBUDepreciationParameters, True);
	Lists.Insert(Metadata.InformationRegisters.OSBUDepreciationParameters, True);
	Lists.Insert(Metadata.InformationRegisters.FixedAssetDepreciationParametersManagementAccounting, True);
	Lists.Insert(Metadata.InformationRegisters.InitialIntangibleAssetsInformation, True);
	Lists.Insert(Metadata.InformationRegisters.InitialFixedAssetsInformation, True);
	Lists.Insert(Metadata.InformationRegisters.IntangibleAssetsAccountingProcedure, True);
	Lists.Insert(Metadata.InformationRegisters.IABookkeepingProcedureBookkeepingAndTaxAccounting, True);
	Lists.Insert(Metadata.InformationRegisters.IABookkeepingProcedureBookkeepingAndTaxAccounting, True);
	Lists.Insert(Metadata.InformationRegisters.IntangibleAssetsAccountingProcedureManagementAccounting, True);
	Lists.Insert(Metadata.InformationRegisters.AccountingProcedureForOSBU, True);
	Lists.Insert(Metadata.InformationRegisters.AccountingProcedureForOSBU, True);
	Lists.Insert(Metadata.InformationRegisters.FixedAssetsAccountingProcedureManagementAccounting, True);
	
	NonCurrentAssetsLocalization.OnFillListsWithAccessRestriction(Lists);
	
EndProcedure

// See PrintManagementOverridable.OnDefinePrintSettings
//
Procedure OnDefinePrintSettings(Settings) Export

	ListOfObjects = Settings.PrintObjects;
	ListOfObjects.Add(Documents.RMOrder);
	ListOfObjects.Add(Documents.RMRequest);
	ListOfObjects.Add(Documents.SetRunningTimeValues);
	ListOfObjects.Add(Documents.IntangibleAssetsAmortizationCharge2_4);
	ListOfObjects.Add(Documents.FixedAssetsDepreciationCharge2_4);
	ListOfObjects.Add(Documents.OBEntryOfLeaseSettlements);
	ListOfObjects.Add(Documents.EntryOfCapitalAssetsBalance2_4);
	ListOfObjects.Add(Documents.EnterRentalInvestmentBalance);
	ListOfObjects.Add(Documents.OBEntrySubAssetsAndComponentsOfDepreciation);
	ListOfObjects.Add(Documents.ReturnAssetsFromLeasee2_4);
	ListOfObjects.Add(Documents.ReturnLeasedAssets);
	ListOfObjects.Add(Documents.IntangibleAssetsOperatingTime);
	ListOfObjects.Add(Documents.SigningOfLeaseContract);
	ListOfObjects.Add(Documents.ChangeIntangibleAssetFinancialDetails2_4);
	ListOfObjects.Add(Documents.ChangeFixedAssetFinancialDetails2_4);
	ListOfObjects.Add(Documents.LeaseTermAdjustment);
	ListOfObjects.Add(Documents.ChangeRentalTerms);
	ListOfObjects.Add(Documents.FixedAssetsCostAdditions2_4);
	ListOfObjects.Add(Documents.AssetActivityRecord);
	ListOfObjects.Add(Documents.ImpairmentFA);
	ListOfObjects.Add(Documents.MergeOfFixedAssets);
	ListOfObjects.Add(Documents.AllocateVariancesToFixedAssetCost);
	ListOfObjects.Add(Documents.ProvideAssetsToLeasee2_4);
	ListOfObjects.Add(Documents.IATransfer2_4);
	ListOfObjects.Add(Documents.FATransfer2_4);
	ListOfObjects.Add(Documents.IARevaluation2_4);
	ListOfObjects.Add(Documents.FARevaluation2_4);
	ListOfObjects.Add(Documents.PreparingForIntangibleAssetSale2_4);
	ListOfObjects.Add(Documents.PreparingForFixedAssetSale2_4);
	ListOfObjects.Add(Documents.ReceiveLeasedAssets);
	ListOfObjects.Add(Documents.ReceivingLeaseServices);
	ListOfObjects.Add(Documents.RDExpenseRecognition);
	ListOfObjects.Add(Documents.IntangibleAssetsInitialRecognition2_4);
	ListOfObjects.Add(Documents.FixedAssetsInitialRecognition2_4);
	ListOfObjects.Add(Documents.RecognizeSubAssetsComponentsOfDepreciation);
	ListOfObjects.Add(Documents.SplitFixedAssets);
	ListOfObjects.Add(Documents.DisposeIntangibleAssets2_4);
	ListOfObjects.Add(Documents.DisposeFixedAssets2_4);
	ListOfObjects.Add(Documents.IntangibleAssetImprovement);
	
	ListOfObjects.Add(Catalogs.LeaseContract);
	ListOfObjects.Add(Catalogs.IntangibleAssets);
	ListOfObjects.Add(Catalogs.Assets);
	
EndProcedure

// Fills an array of structures that will be used for initial filling and restoring the initial filling of profiles.
//
// Parameters:
//  ProfilesDetails - Array of See AccessManagement.NewAccessGroupProfileDescription
//  ParametersOfUpdate - Structure:
//   * UpdateModifiedProfiles - Boolean - the initial value is True.
//   * DenyProfilesChange - Boolean - the initial value is True.
//       If set to False, then the supplied profiles can not only be viewed, but also edited.
//   * UpdatingAccessGroups     - Boolean - the initial value is True.
//   * UpdatingAccessGroupsWithObsoleteSettings - Boolean - the initial value is False.
//       If set to True, the value settings made by the administrator for
//       the type of access that was removed from the profile will also be removed from the access groups.
//
Procedure FillInSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate) Export
	
	AddAccountantProfileForNonCurrentAssets(ProfilesDetails);
	AddProfileResponsibleForMaintainingOperationalFacilities(ProfilesDetails);
	
EndProcedure

// See ChartsOfCharacteristicTypes.ExpenseItems.ProcessingSelectionParameters
Procedure ProcessingParametersForSelectingExpenseItem(Parameters) Export
	
	AccountingProcedureAC = CommonClientServer.StructureProperty(Parameters, "AccountingProcedureAC", Undefined);
	AccountingProcedureMA = CommonClientServer.StructureProperty(Parameters, "AccountingProcedureMA", Undefined);
	AccountingProcedureTA = CommonClientServer.StructureProperty(Parameters, "AccountingProcedureTA", Undefined);
	
	DistributionOptions = NonCurrentAssetsClientServer.AvailableCostSharingOptions(AccountingProcedureMA);
	If DistributionOptions.Count() <> 0 Then
		Parameters.Filter.Insert("CostAllocationOptionManag", New FixedArray(DistributionOptions));
	EndIf; 
	
	DistributionOptions = NonCurrentAssetsClientServer.AvailableCostSharingOptions(AccountingProcedureAC);
	If DistributionOptions.Count() <> 0 Then
		Parameters.Filter.Insert("CostAllocationOptionLocal", New FixedArray(DistributionOptions));
	EndIf; 
	
	DistributionOptions = NonCurrentAssetsClientServer.AvailableCostSharingOptions(AccountingProcedureTA);
	If DistributionOptions.Count() <> 0 Then
		Parameters.Filter.Insert("CostAllocationOptionTax", New FixedArray(DistributionOptions));
	EndIf; 
		
EndProcedure

// See also updating the information base undefined.At firstfillingelements
//
// Parameters:
//  LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//  Items   - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//  TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	
	NonCurrentAssetsLocalization.OnInitialItemsFilling(LanguagesCodes, Items, TabularSections);
	
	Set = Items.Add();
	Set.PredefinedSetName = "Document_OBEntrySubAssetsAndComponentsOfDepreciation";
	Set.Ref = New UUID("476718b2-0391-48dc-95ec-76501d38b5c2");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Nhập số dư bộ phận và thành phần khấu hao';
		|ru = 'Ввод остатков узлов и компонентов амортизации';
		|en = 'OB entry: sub-assets and components of depreciation';
		|it = 'Ввод остатков узлов и компонентов амортизации';
		|pl = 'OB entry: sub-assets and components of depreciation';
		|tr = 'Bakiye girişi: alt varlıklar ve amortisman bileşenleri'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Document_IATransfer2_4";
	Set.Ref = New UUID("bb2ad558-3d21-473e-aa2e-1e21994eda95");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Điều chuyển tài sản cố định vô hình';
		|ru = 'Перемещение НМА';
		|en = 'Transfer intangible assets';
		|it = 'Перемещение НМА';
		|pl = 'Przemieszczenie wartości niematerialnych';
		|tr = 'GMA transferi'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Document_AssetActivityRecord";
	Set.Ref = New UUID("45db92d0-bf39-42af-b189-9f819039e04e");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Thời gian sử dụng tài sản đang vận hành';
		|ru = 'Наработки объектов эксплуатации';
		|en = 'Asset activity records';
		|it = 'Наработки объектов эксплуатации';
		|pl = 'Ilość pracy wykonanej przez obiekty eksploatacji';
		|tr = 'Varlık işletme süresi'", LanguagesCodes); // @NStr-2
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

// Finds objects of exploitation by barcode.
//
// Parameters:
//  BarcodeData_5 - Structure - Barcode data.
//  PickingParameters - Structure - Selection parameters that must be met by operational objects.
// 
// Returns:
//  Array - list of operational objects.
//
Function FindObjectsOfOperationByBarcodes(BarcodeData_5, PickingParameters = Undefined) Export
	
	Result = FindObjectsByBarcodes(BarcodeData_5, PickingParameters);
	
	MessageTemplate = NStr("vi = 'Không tìm thấy đối tượng với số đăng ký  %1';
							|ru = 'Объект эксплуатации с инвентарным номером %1 не найден';
							|en = 'An asset with inventory number %1 is not found'; fa = 'An asset with inventory number %1 is not found';
							|it = 'Oggetto di utilizzo con numero di inventario %1 non trovato';
							|pl = 'Obiekt operacji z numerem inwentarza %1 nie został znaleziony';
							|tr = 'Envanter numarası %1 olan varlık bulunamadı'");
	For Each Barcode In Result.NotFound_1 Do
		MessageText = StrTemplate(MessageTemplate, Barcode);
		Common.MessageToUser(MessageText); 
	EndDo; 
	
	MessageTemplate = NStr("vi = 'Không thể thêm đối tượng hoạt động ""%1"" vì không thỏa mãn điều kiện lựa chọn';
							|ru = 'Объект эксплуатации ""%1"" не может быть добавлен, т.к. он не удовлетворяет условиям выбора';
							|en = 'The asset ""%1"" cannot be added, as it does not meet selection conditions'; fa = 'The asset ""%1"" cannot be added, as it does not meet selection conditions';
							|it = 'Oggetto di utilizzo ""%1"" impossibile da aggiungere, poiché non soddisfa le condizioni di selezione';
							|pl = 'Nie można dodać obiektu operacji „%1”, ponieważ nie spełnia warunków wyboru';
							|tr = '""%1"" varlığı seçim koşullarını karşılamadığı için eklenemiyor'");
	For Each ObjectReference In Result.DoNotFit Do
		MessageText = StrTemplate(MessageTemplate, ObjectReference);
		Common.MessageToUser(MessageText, ObjectReference); 
	EndDo; 
	
	Return Result.ObjectsArray;
	
EndFunction

// Finds fixed assets by barcodes.
//
// Parameters:
//  BarcodeData_5 - Structure - Barcode data.
//  PickingParameters - Structure - Selection parameters that must be met by operational objects.
// 
// Returns:
//  Array - list of operational objects.
//
Function FindFixedAssetsByBarcodes(BarcodeData_5, PickingParameters = Undefined) Export

	Result = FindObjectsByBarcodes(BarcodeData_5, PickingParameters);
	ReportBarcodeSearchResults(Result);
	
	Return Result.ObjectsArray;

EndFunction

// Finds objects of exploitation by barcode.
// 
// Parameters:
//  BarcodeData_5 - Structure - Barcode data.
//  PickingParameters - Structure - Selection parameters that must be met by operational objects.
// 	
// Returns:
// 	Structure - Contains:
//    * ObjectsArray - Array of CatalogRef.Assets - found objects.
//    * NotFound_1 - Array of String - barcodes for which objects could not be found.
//    * DoNotFit - Array of CatalogRef.Assets - Objects that do not match the selection parameters.
Function FindObjectsByBarcodes(BarcodeData_5, PickingParameters) Export

	Result = New Structure;
	Result.Insert("ObjectsArray", New Array);
	Result.Insert("DoNotFit", New Array);
	Result.Insert("NotFound_1", New Array);

	ArrayOfBarcodes = ArrayOfBarcodes(BarcodeData_5);
	
	If ArrayOfBarcodes.Count() = 0 Then
		Return Result;
	EndIf; 
	
	QueryText = 
	"SELECT
	|	Assets.Ref AS Ref,
	|	Assets.AssetID AS AssetID
	|FROM
	|	Catalog.Assets AS Assets
	|WHERE
	|	Assets.AssetID IN(&ArrayOfBarcodes)
	|
	|ORDER BY
	|	Assets.Description,
	|	Assets.AssetID";
	
	Query = New Query(QueryText);
	Query.SetParameter("ArrayOfBarcodes", ArrayOfBarcodes);
	
	QueryResult = Query.Execute().Unload();
	
	ObjectsArray = QueryResult.UnloadColumn("Ref");
	
	NotFound_1 = New Array;
	For Each Barcode In ArrayOfBarcodes Do
		If QueryResult.Find(Barcode, "AssetID") = Undefined Then
			NotFound_1.Add(Barcode);
		EndIf; 
	EndDo; 
	
	DoNotFit = New Array;
	If PickingParameters <> Undefined Then
		DoNotFit = DeleteObjectsThatDoNotMatchSelection(ObjectsArray, PickingParameters);
	EndIf; 
	
	Result.ObjectsArray = ObjectsArray;
	Result.DoNotFit = DoNotFit;
	Result.NotFound_1 = NotFound_1;
	
	Return Result;

EndFunction

// Reports the barcode search results.
// 
// Parameters:
// 	SearchResult - See FindObjectsByBarcodes
Procedure ReportBarcodeSearchResults(SearchResult) Export
	
	MessageTemplate = NStr("vi = 'Không tìm thấy tài sản cố định có số kiểm kê %1';
							|ru = 'Основное средство с инвентарным номером %1 не найдено';
							|en = 'Fixed asset with inventory number %1 is not found'; fa = 'Fixed asset with inventory number %1 is not found';
							|it = 'Capitale fisso con numero di inventario %1 non trovato';
							|pl = 'Środek trwały z numerem inwentaryzacyjnym %1 nie został znaleziony';
							|tr = 'Envanter numarası %1 olan sabit kıymet bulunamadı'");
	For Each Barcode In SearchResult.NotFound_1 Do
		MessageText = StrTemplate(MessageTemplate, Barcode);
		Common.MessageToUser(MessageText); 
	EndDo; 
	
	MessageTemplate = NStr("vi = 'Không thể thêm tài sản cố định ""%1"" vào chứng từ bởi vì tài sản này không thỏa mãn điều kiện lọc';
							|ru = 'Основное средство ""%1"" не может быть добавлено в документ, т.к. оно не удовлетворяет условиям выбора';
							|en = 'The fixed asset ""%1"" cannot be added to the document, as it does not meet selection conditions'; fa = 'The fixed asset ""%1"" cannot be added to the document, as it does not meet selection conditions';
							|it = 'Capitale fisso ""%1"" impossibile da aggiungere, poiché non soddisfa le condizioni di selezione';
							|pl = 'Środek trwały ""%1"" nie można dodać do dokumentu, ponieważ nie spełnia warunków wyboru';
							|tr = '""%1"" sabit kıymeti seçim koşullarını karşılamadığı için belgeye eklenemiyor'");
	For Each ObjectReference In SearchResult.DoNotFit Do
		MessageText = StrTemplate(MessageTemplate, ObjectReference);
		Common.MessageToUser(MessageText, ObjectReference); 
	EndDo; 
	
EndProcedure

// Retrieves the list of barcodes from the input result.
// 
// Parameters:
//  BarcodeData_5 - Structure, Array of String - Barcode data.
//  
// Returns:
// 	Array - 
Function ArrayOfBarcodes(BarcodeData_5) Export
	
	ArrayOfBarcodes = New Array;
	If TypeOf(BarcodeData_5) = Type("Array") Then
		For Each BarcodeString In BarcodeData_5 Do
			If ValueIsFilled(BarcodeString.Barcode) Then
				ArrayOfBarcodes.Add(BarcodeString.Barcode);
			EndIf;
		EndDo;
	ElsIf ValueIsFilled(BarcodeData_5.Barcode) Then
		ArrayOfBarcodes.Add(BarcodeData_5.Barcode);
	EndIf;
	
	TMCommonUse.DeleteDuplicateElementsFromArray(ArrayOfBarcodes);
	
	Return ArrayOfBarcodes;
	
EndFunction
 
#EndRegion

#Region HandlersForMonthClosingStages

#Region FillInActualCostOfFixedAssetsWithDisabledCostAccounting

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - (See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth)
// 	CurrentParent - String - group ID.
Procedure AddStage_FillInActualCostOfFixedAssetsWithDisabledCostAccounting(StepsTable,CurrentParent) Export
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.FillInActualCostOfFixedAssetsWithDisabledCostAccounting);
	
	NewRow.MultilingualName = "vi = 'Điền vào giá trị thực của tài sản dài hạn khi hạch toán giá thành bị vô hiệu hóa';
								|ru = 'Заполнение фактической стоимости внеоборотных активов при отключенном учете себестоимости';
								|en = 'Fill in actual cost of fixed assets with disabled cost accounting';
								|it = 'La compilazione del costo effettivo delle attività non correnti al calcolo dei costo disabilitato';
								|pl = 'Wypełnienie rzeczywistego kosztu aktywów trwałych podczas wyłączonej ewidencji kosztów własnych';
								|tr = 'Maliyet muhasebesi devre dışı bırakıldığında duran varlıkların gerçek değerini doldurma'"; // @NStr-1
	NewRow.PerformedManually = True;
	NewRow.TextExecute     = NStr("vi = 'Điền';
									|ru = 'Заполнить';
									|en = 'Fill'; fa = 'پرکردن';
									|it = 'Compilare';
									|pl = 'Fill';
									|tr = 'Doldur'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"NonCurrentAssets.Use_FillingInActualCostOfBHAWhenCostAccountingIsDisabled");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.DataProcessors.FillInActualCostOfFixedAssetsWithDisabledCostAccounting.Forms.Form.FullName());
EndProcedure

// The procedure determines whether the stage must be completed.
//
// Parameters:
//  HandlerParameters - Structure - parameters of the stage event handler.
//
Procedure Use_FillingInActualCostOfBHAWhenCostAccountingIsDisabled(HandlerParameters) Export
	
	If Not NonCurrentAssets.VNAManagementIsUsed_2_4() Then
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Kế toán tài sản dài hạn bị vô hiệu hóa.';
				|ru = 'Учет внеоборотных активов отключен.';
				|en = 'Accounting of fixed assets disabled.'; fa = 'Accounting of fixed assets disabled.';
				|it = 'La contabilità degli attivi non circolanti è disattivata.';
				|pl = 'Ewidencja aktyw pozaobrotowych jest odłączona.';
				|tr = 'Duran varlıkların muhasebeleştirilmesi devre dışı bırakılmıştır.'", Common.DefaultLanguageCode()));
			
		Return; 
	EndIf; 
	
	If GetFunctionalOption("UseCostAccounting") 
		And Not ValueIsFilled(Constants.CostAccountingStartDate.Get()) Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Với kế toán chi phí được bật, không có chi phí được yêu cầu.';
				|ru = 'При включенном учете себестоимости заполнение стоимости не требуется.';
				|en = 'When the cost accounting is off, filling of the cost is not required.'; fa = 'When the cost accounting is off, filling of the cost is not required.';
				|it = 'Quando è abilitata la contabilità dei costi, non è richiesto alcun costo.';
				|pl = 'Gdy ewidencja kosztów własnych jest włączona, wypełnienie wartości nie jest konieczne.';
				|tr = 'Maliyet muhasebesi etkinleştirildiğinde, hiçbir maliyetin doldurulması gerekmez.'", Common.DefaultLanguageCode()));
			
		Return; 
	EndIf;
	
	If DataProcessors.FillInActualCostOfFixedAssetsWithDisabledCostAccounting.ThereAreDocumentsForProcessing() Then
		
		MessageText = NStr("vi = 'chứng từ được tìm thấy trong đó giá trị được chỉ ra trong chứng từ khác với chứng từ thực tế.';
							|ru = 'Обнаружены документы, в которых стоимость, указанная в документе, отличается от фактической.';
							|en = 'The documents are found where the cost specified in the document is different from the actual cost.'; fa = 'The documents are found where the cost specified in the document is different from the actual cost.';
							|it = 'Rilevati i documenti in cui il valore specificato nel documento differisce dall''attuale.';
							|pl = 'Istnieją dokumenty, w których wartość określona w dokumencie różni się od rzeczywistej.';
							|tr = 'Belgede belirtilen değerin gerçek maliyetten farklı olduğu belgeler tespit edilmiştir.'", Common.DefaultLanguageCode());
		
		MonthEndTransactionsServer.SetStateFailed(
			HandlerParameters,
			MessageText,,,
			Enums.AccountingIssueSeverity.Error);
		
	Else
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có chứng từ cần phải điền vào chi phí.';
				|ru = 'Нет документов, в которых требуется заполнить стоимость.';
				|en = 'No documents where filling of the cost is required.'; fa = 'No documents where filling of the cost is required.';
				|it = 'Non ci sono documenti in cui è richiesto compilare il costo.';
				|pl = 'Brak dokumentów, w których konieczne jest wypełnienie kosztów.';
				|tr = 'Maliyetin doldurulmasını gerektiren herhangi bir evrak yoktur.'", Common.DefaultLanguageCode()));
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Other

// Determines whether the control is used in version 2.4 of the APP.
//
// Parameters:
//  Period	 - Date - On what date to check (if not specified, it is checked for the current date).
// 
// Returns:
//  Boolean - True if VNA version 2.4 control is used.
//
Function VNAManagementIsUsed_2_4(Period = '000101010000') Export

	If Not GetFunctionalOption("UseNonCurrentAssets2_4") Then
		Return False;
	EndIf;
	
	Return NonCurrentAssetsLocalization.VNAManagementIsUsed_2_4(Period);

EndFunction

// Determines whether VNA management is used.
// 
// Returns:
//  Boolean - True if VNA control is used.
//
Function VNAManagementIsUsed() Export

	Return GetFunctionalOption("UseNonCurrentAssets2_4")
			Or NonCurrentAssetsLocalization.VNAManagementIsUsed();

EndFunction
  
// Determines the location of the fixed asset.
//
// Parameters:
//  FixedAsset - CatalogRef.Assets	 - Fixed asset.
//  Date - Date	 - date.
// 
// Returns:
//  Structure - Contains information about the location:
//  * Organization - CatalogRef.Companies -
//  * FinanciallyLiablePerson - CatalogRef.Persons -
//  * FixedAssetsLocation - CatalogRef.BusinessStructure -
//  * LocationAddress - String -
//  * Leaseholder - CatalogRef.Companies, CatalogRef.Counterparties -
//  * LeaseholderBusinessUnit - CatalogRef.BusinessStructure -
//  * LeaseholderEmployeeInCharge - CatalogRef.Persons -
//
Function FALocation(FixedAsset, Date = '000101010000') Export

	QueryText = 
	"SELECT ALLOWED
	|	FALocation.Organization AS Organization,
	|	FALocation.FinanciallyLiablePerson AS FinanciallyLiablePerson,
	|	FALocation.FixedAssetsLocation AS FixedAssetsLocation,
	|	FALocation.LocationAddress AS LocationAddress,
	|	FALocation.Leaseholder AS Leaseholder,
	|	FALocation.LeaseholderBusinessUnit AS LeaseholderBusinessUnit,
	|	FALocation.LeaseholderEmployeeInCharge AS LeaseholderEmployeeInCharge,
	|	AssetsLeasedOut.Contract AS Contract
	|FROM
	|	InformationRegister.FALocation.SliceLast(
	|		&Date, 
	|		CorrectionDate = DATETIME(1,1,1) 
	|			AND FixedAsset = &FixedAsset) AS FALocation
	|
	|		LEFT JOIN InformationRegister.AssetsLeasedOut.SliceLast(, FixedAsset = &FixedAsset) AS AssetsLeasedOut
	|		ON AssetsLeasedOut.FixedAsset = FALocation.FixedAsset
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Date", Date);
	Query.SetParameter("FixedAsset", FixedAsset);
	
	Result = Query.Execute();
	
	FALocation = New Structure;
	For Each QueryColumn In Result.Columns Do
		FALocation.Insert(QueryColumn.Name);
	EndDo;
	
	Selection = Result.Select();
	If Selection.Next() Then
		FillPropertyValues(FALocation, Selection);
	EndIf;
	
	Return FALocation;
	
EndFunction

// Determines the accounting location of an intangible asset.
//
// Parameters:
//  IntangibleAsset	 - CatalogRef.IntangibleAssets - intangible asset.
// 
// Returns:
//  Structure - Contains information about the place of registration:
//  * Organization - CatalogRef.Companies -
//  * Department - CatalogRef.BusinessStructure -
//
Function IntangibleAssetsRegistrationPlace(IntangibleAsset) Export

	QueryText = 
	"SELECT ALLOWED
	|	IntangibleAssetsRegistrationPlace.Organization,
	|	IntangibleAssetsRegistrationPlace.Department AS Department
	|FROM
	|	InformationRegister.IntangibleAssetsRegistrationPlace.SliceLast(, IntangibleAsset = &IntangibleAsset) AS IntangibleAssetsRegistrationPlace";
	
	Query = New Query(QueryText);
	Query.SetParameter("IntangibleAsset", IntangibleAsset);
	
	Result = Query.Execute();
	
	IntangibleAssetsRegistrationPlace = New Structure;
	For Each QueryColumn In Result.Columns Do
		IntangibleAssetsRegistrationPlace.Insert(QueryColumn.Name);
	EndDo;
	
	Selection = Result.Select();
	If Selection.Next() Then
		FillPropertyValues(IntangibleAssetsRegistrationPlace, Selection);
	EndIf;

	Return IntangibleAssetsRegistrationPlace;
	
EndFunction

// Determines the location and information about the lessor of the fixed asset.
//
// Parameters:
//  FixedAsset - CatalogRef.Assets	 - Fixed asset.
// 
// Returns:
//  Structure - Contains information about the location:
//  	* Organization - CatalogRef.Companies -
// 		* Partner - CatalogRef.Partners -
//  	* Counterparty - CatalogRef.Counterparties -
//  	* Contract - CatalogRef.LeaseContract, CatalogRef.CounterpartyContracts - 
//  	* FinanciallyLiablePerson - CatalogRef.Persons -
//  	* FixedAssetsLocation - CatalogRef.BusinessStructure -
//  	* LocationAddress - String -
//
Function LocationAndLandlordFA(FixedAsset) Export

	QueryText = 
	"SELECT ALLOWED
	|	FALocation.Organization AS Organization,
	|	FALocation.FinanciallyLiablePerson AS FinanciallyLiablePerson,
	|	FALocation.FixedAssetsLocation AS FixedAssetsLocation,
	|	FALocation.LocationAddress AS LocationAddress,
	|	LeasedAsset.Partner AS Partner,
	|	LeasedAsset.Counterparty AS Counterparty,
	|	LeasedAsset.Contract AS Contract
	|FROM
	|	InformationRegister.FALocation.SliceLast(, CorrectionDate = DATETIME(1,1,1) AND FixedAsset = &FixedAsset) AS FALocation
	|
	|		LEFT JOIN InformationRegister.LeasedAsset.SliceLast(, FixedAsset = &FixedAsset) AS LeasedAsset
	|		ON LeasedAsset.FixedAsset = FALocation.FixedAsset";
	
	Query = New Query(QueryText);
	Query.SetParameter("FixedAsset", FixedAsset);
	
	Result = Query.Execute();
	
	FALocation = New Structure;
	For Each QueryColumn In Result.Columns Do
		FALocation.Insert(QueryColumn.Name);
	EndDo;
	
	Selection = Result.Select();
	If Selection.Next() Then
		FillPropertyValues(FALocation, Selection);
	EndIf;
	
	Return FALocation;
	
EndFunction

// Returns information about the cost and depreciation of the asset.
//
// Parameters:
//  FixedAsset - CatalogRef.Assets	 - The main tool for which you need to get information.
// 
// Returns:
//  Structure - Contains properties: Depreciation,amortisationregl,depreciation,depreciation,depreciation,depreciation,
//  								Amortizationcf,amortizationcf,amortizationcf,amortizationcf,
//  								Cost,costregl,costnu,COSTPR,COSTVR,
//  								COSTCF,COSTCF,COSTCF,COSTCF.
//
Function CostAndDepreciationOfFA(FixedAsset) Export

	CostAndDepreciation = New Structure("Depreciation,DepreciationLocal,DepreciationInTaxAccounting,DepreciationPermanentDifferences,DepreciationTD,
											|FixedAssetDepreciationTargetFinancing,DepreciationTaxAccountingTargetFinancing,DepreciationTargetFinancingPD,DepreciationOfTargetFinancingTD,
											|Cost,LocalCost,CostInTaxAccounting,CostPermanentDifference,CostTemporaryDifference,
											|CostTargetFinancing,CostTargetFinancingTA,CostTargetFinancingPD,CostTargetFinancingTD,SecurityDepositValue,
											|ImpairmentLocalAssets, ImpairmenMan");
	
	For Each Column In CostAndDepreciation Do
		CostAndDepreciation[Column.Key] = 0;
	EndDo;
	
	If Not ValueIsFilled(FixedAsset) Then
		Return CostAndDepreciation;
	EndIf;
	
	Organization = Undefined;
	FALocation = FALocation(FixedAsset);
	If FALocation <> Undefined Then
		Organization = FALocation.Organization
	EndIf;
	
	If Not ValueIsFilled(Organization) Then
		Return CostAndDepreciation;
	EndIf;
	
	QueryText =
	"SELECT ALLOWED
	|	ISNULL(FACostBalance.CostBalance, 0) AS Cost,
	|	ISNULL(FACostBalance.LocalCostBalance, 0) AS LocalCost,
	|	ISNULL(FACostBalance.CostInTaxAccountingBalance, 0) AS CostInTaxAccounting,
	|	ISNULL(FACostBalance.CostPermanentDifferenceBalance, 0) AS CostPermanentDifference,
	|	ISNULL(FACostBalance.CostTemporaryDifferenceBalance, 0) AS CostTemporaryDifference,
	|	ISNULL(FACostBalance.CostTargetFinancingBalance, 0) AS CostTargetFinancing,
	|	ISNULL(FACostBalance.CostTargetFinancingTABalance, 0) AS CostTargetFinancingTA,
	|	ISNULL(FACostBalance.CostTargetFinancingPDBalance, 0) AS CostTargetFinancingPD,
	|	ISNULL(FACostBalance.CostTargetFinancingTDBalance, 0) AS CostTargetFinancingTD,
	|
	|	ISNULL(-FixedAssetsDepreciationChargeBalance.DepreciationBalance, 0) AS Depreciation,
	|	ISNULL(-FixedAssetsDepreciationChargeBalance.DepreciationLocalBalance, 0) AS DepreciationLocal,
	|	ISNULL(-FixedAssetsDepreciationChargeBalance.DepreciationInTaxAccountingBalance, 0) AS DepreciationInTaxAccounting,
	|	ISNULL(-FixedAssetsDepreciationChargeBalance.DepreciationPermanentDifferencesBalance, 0) AS DepreciationPermanentDifferences,
	|	ISNULL(-FixedAssetsDepreciationChargeBalance.DepreciationTDBalance, 0) AS DepreciationTD,
	|	ISNULL(-FixedAssetsDepreciationChargeBalance.FixedAssetDepreciationTargetFinancingBalance, 0) AS FixedAssetDepreciationTargetFinancing,
	|	ISNULL(-FixedAssetsDepreciationChargeBalance.DepreciationTaxAccountingTargetFinancingBalance, 0) AS DepreciationTaxAccountingTargetFinancing,
	|	ISNULL(-FixedAssetsDepreciationChargeBalance.DepreciationTargetFinancingPDBalance, 0) AS DepreciationTargetFinancingPD,
	|	ISNULL(-FixedAssetsDepreciationChargeBalance.DepreciationOfTargetFinancingTDBalance, 0) AS DepreciationOfTargetFinancingTD,
	|
	|	ISNULL(FACostBalance.SecurityDepositValueBalance, 0) AS SecurityDepositValue,
	|
	|	ISNULL(-ImpairmentFABalance.ImpairmenManBalance, 0) AS ImpairmenMan,
	|	ISNULL(-ImpairmentFABalance.ImpairmentLocalAssetsBalance, 0) AS ImpairmentLocalAssets
	|
	|FROM
	|	Catalog.Assets AS Assets
	|
	|		LEFT JOIN AccumulationRegister.FixedAssetsDepreciationCharge.Balance(
	|				,
	|				Organization = &Organization
	|					AND FixedAsset = &FixedAsset) AS FixedAssetsDepreciationChargeBalance
	|		ON Assets.Ref = FixedAssetsDepreciationChargeBalance.FixedAsset
	|
	|		LEFT JOIN AccumulationRegister.FACost.Balance(
	|				,
	|				Organization = &Organization
	|					AND FixedAsset = &FixedAsset) AS FACostBalance
	|		ON Assets.Ref = FACostBalance.FixedAsset
	|
	|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
	|				,
	|				CorrectionDate = DATETIME(1,1,1)
	|					AND Organization = &Organization
	|					AND FixedAsset = &FixedAsset) AS FixedAssetsAccountingProcedureManagementAccounting
	|		ON Assets.Ref = FixedAssetsAccountingProcedureManagementAccounting.FixedAsset
	|
	|		LEFT JOIN InformationRegister.AccountingProcedureForOSBU.SliceLast(
	|				,
	|				CorrectionDate = DATETIME(1,1,1)
	|					AND Organization = &Organization
	|					AND FixedAsset = &FixedAsset) AS AccountingProcedureForOSBU
	|		ON Assets.Ref = AccountingProcedureForOSBU.FixedAsset
	|
	|		LEFT JOIN AccumulationRegister.ImpairmentFA.Balance(
	|				,
	|				Organization = &Organization
	|					AND NonCurrentAsset = &FixedAsset) AS ImpairmentFABalance
	|		ON Assets.Ref = ImpairmentFABalance.NonCurrentAsset
	|WHERE
	|	Assets.Ref = &FixedAsset";
	
	Query = New Query(QueryText);
	Query.SetParameter("FixedAsset", FixedAsset);
	Query.SetParameter("Organization", Organization);
	
	Result = Query.Execute();
	Selection = Result.Select();
	Selection.Next();
	FillPropertyValues(CostAndDepreciation, Selection);

	Return CostAndDepreciation;
	
EndFunction

// Returns information about the cost and depreciation of the IA.
//
// Parameters:
//  IntangibleAsset - CatalogRef.IntangibleAssets	 - An intangible asset for which you need to get information.
// 
// Returns:
//  Structure - Cost and depreciation information.
//
Function CostAndDepreciationOfIa(IntangibleAsset) Export

	CostAndDepreciation = New Structure("Depreciation,DepreciationLocal,DepreciationInTaxAccounting,DepreciationPermanentDifferences,DepreciationTD,
											|FixedAssetDepreciationTargetFinancing,DepreciationTaxAccountingTargetFinancing,DepreciationTargetFinancingPD,DepreciationOfTargetFinancingTD,
											|Cost,LocalCost,CostInTaxAccounting,CostPermanentDifference,CostTemporaryDifference,
											|CostTargetFinancing,CostTargetFinancingTA,CostTargetFinancingPD,CostTargetFinancingTD,
											|ImpairmenMan,ImpairmentLocalAssets");
	
	For Each Column In CostAndDepreciation Do
		CostAndDepreciation[Column.Key] = 0;
	EndDo;
	
	If Not ValueIsFilled(IntangibleAsset) Then
		Return CostAndDepreciation;
	EndIf;

	Organization = Undefined;
	FALocation = IntangibleAssetsRegistrationPlace(IntangibleAsset);
	If FALocation <> Undefined Then
		Organization = FALocation.Organization
	EndIf;
	
	If Not ValueIsFilled(Organization) Then
		Return CostAndDepreciation;
	EndIf;
	
	QueryText =
	"SELECT ALLOWED
	|	IACostBalance.IntangibleAsset AS IntangibleAsset,
	|	IACostBalance.CostBalance AS CostInManagementAccounting,
	|	IACostBalance.LocalCostBalance AS CostInAccounting,
	|	IACostBalance.CostInTaxAccountingBalance AS CostInTaxAccounting,
	|	IACostBalance.CostPermanentDifferenceBalance AS CostPermanentDifference,
	|	IACostBalance.CostTemporaryDifferenceBalance AS CostTemporaryDifference,
	|	IACostBalance.CostTargetFinancingBalance AS CostTargetFinancing,
	|	IACostBalance.CostTargetFinancingTABalance AS CostTargetFinancingTA,
	|	IACostBalance.CostTargetFinancingPDBalance AS CostTargetFinancingPD,
	|	IACostBalance.CostTargetFinancingTDBalance AS CostTargetFinancingTD,
	|
	|	CASE
	|		WHEN IACostBalance.CostTemporaryDifferenceBalance 
	|				+ IACostBalance.CostPermanentDifferenceBalance
	|				+ IACostBalance.CostTargetFinancingTDBalance 
	|				+ IACostBalance.CostTargetFinancingPDBalance = 0
	|			THEN 0
	|		ELSE (IACostBalance.CostPermanentDifferenceBalance + IACostBalance.CostTargetFinancingPDBalance)
	|				/ (IACostBalance.CostTemporaryDifferenceBalance 
	|					+ IACostBalance.CostPermanentDifferenceBalance
	|					+ IACostBalance.CostTargetFinancingTDBalance 
	|					+ IACostBalance.CostTargetFinancingPDBalance)
	|	END AS ShareOfPD
	|
	|INTO IACostBalance
	|
	|FROM
	|	AccumulationRegister.IACost.Balance(
	|			,
	|			Organization = &Organization
	|				AND IntangibleAsset = &IntangibleAsset) AS IACostBalance
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN IntangibleAssets.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|			THEN ISNULL(InitialIntangibleAssetsInformation.InitialCostMA, 0)
	|					- ISNULL(IACostBalance.CostInManagementAccounting, 0)
	|		ELSE ISNULL(-IntangibleAssetsAmortizationChargeBalance.DepreciationBalance, 0)
	|	END AS Depreciation,
	|
	// DepreciationLocal
	|	CASE
	|		WHEN IntangibleAssets.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|			THEN ISNULL(InitialIntangibleAssetsInformation.InitialCostLocalAccounting, 0)
	|					- ISNULL(IACostBalance.CostInAccounting, 0)
	|					- ISNULL(IACostBalance.CostTargetFinancing, 0)
	|		ELSE ISNULL(-IntangibleAssetsAmortizationChargeBalance.DepreciationLocalBalance, 0)
	|	END AS DepreciationLocal,
	|
	// FixedAssetDepreciationTargetFinancing
	|	CASE
	|		WHEN IntangibleAssets.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|			THEN 0
	|		ELSE ISNULL(-IntangibleAssetsAmortizationChargeBalance.FixedAssetDepreciationTargetFinancingBalance, 0)
	|	END AS FixedAssetDepreciationTargetFinancing,
	|
	// DepreciationInTaxAccounting
	|	CASE
	|		WHEN IntangibleAssets.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|			THEN ISNULL(InitialIntangibleAssetsInformation.InitialCostTA, 0)
	|					- ISNULL(IACostBalance.CostInTaxAccounting, 0)
	|					- ISNULL(IACostBalance.CostTargetFinancingTA, 0)
	|		ELSE ISNULL(-IntangibleAssetsAmortizationChargeBalance.DepreciationInTaxAccountingBalance, 0)
	|	END AS DepreciationInTaxAccounting,
	|
	// DepreciationTaxAccountingTargetFinancing
	|	CASE
	|		WHEN IntangibleAssets.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|			THEN 0
	|		ELSE ISNULL(-IntangibleAssetsAmortizationChargeBalance.DepreciationTaxAccountingTargetFinancingBalance, 0)
	|	END AS DepreciationTaxAccountingTargetFinancing,
	|
	// DepreciationPermanentDifferences
	|	CASE
	|		WHEN IntangibleAssets.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|			THEN ISNULL(InitialIntangibleAssetsInformation.InitialCostPD, 0) 
	|					- ISNULL(IACostBalance.CostPermanentDifference, 0) 
	|					- ISNULL(IACostBalance.CostTargetFinancingPD, 0)
	|		ELSE ISNULL(-IntangibleAssetsAmortizationChargeBalance.DepreciationPermanentDifferencesBalance, 0)
	|	END AS DepreciationPermanentDifferences,
	|
	// DepreciationTargetFinancingPD
	|	CASE
	|		WHEN IntangibleAssets.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|			THEN 0
	|		ELSE ISNULL(-IntangibleAssetsAmortizationChargeBalance.DepreciationTargetFinancingPDBalance, 0)
	|	END AS DepreciationTargetFinancingPD,
	|
	// DepreciationTD
	|	CASE
	|		WHEN IntangibleAssets.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|			THEN ISNULL(InitialIntangibleAssetsInformation.InitialCostLocalAccounting, 0)
	|					- ISNULL(InitialIntangibleAssetsInformation.InitialCostTA, 0)
	|					- ISNULL(InitialIntangibleAssetsInformation.InitialCostPD, 0)
	|					- ISNULL(IACostBalance.CostTemporaryDifference, 0) 
	|					- ISNULL(IACostBalance.CostTargetFinancingTD, 0)
	|		ELSE ISNULL(-IntangibleAssetsAmortizationChargeBalance.DepreciationTDBalance, 0)
	|	END AS DepreciationTD,
	|
	// DepreciationOfTargetFinancingTD
	|	CASE
	|		WHEN IntangibleAssets.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|			THEN 0
	|		ELSE ISNULL(-IntangibleAssetsAmortizationChargeBalance.DepreciationOfTargetFinancingTDBalance, 0)
	|	END AS DepreciationOfTargetFinancingTD,
	|
	// Cost
	|	CASE
	|		WHEN IntangibleAssets.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|			THEN ISNULL(InitialIntangibleAssetsInformation.InitialCostMA, 0)
	|		ELSE ISNULL(IACostBalance.CostInManagementAccounting, 0)
	|	END AS Cost,
	|
	// LocalCost
	|	CASE
	|		WHEN IntangibleAssets.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|			THEN ISNULL(InitialIntangibleAssetsInformation.InitialCostLocalAccounting, 0)
	|		ELSE ISNULL(IACostBalance.CostInAccounting, 0)
	|	END AS LocalCost,
	|
	// CostTargetFinancing
	|	CASE
	|		WHEN IntangibleAssets.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|			THEN 0
	|		ELSE ISNULL(IACostBalance.CostTargetFinancing, 0)
	|	END AS CostTargetFinancing,
	|
	// CostInTaxAccounting
	|	CASE
	|		WHEN IntangibleAssets.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|			THEN ISNULL(InitialIntangibleAssetsInformation.InitialCostTA, 0)
	|		ELSE ISNULL(IACostBalance.CostInTaxAccounting, 0)
	|	END AS CostInTaxAccounting,
	|
	// CostTargetFinancingTA
	|	CASE
	|		WHEN IntangibleAssets.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|			THEN 0
	|		ELSE ISNULL(IACostBalance.CostTargetFinancingTA, 0)
	|	END AS CostTargetFinancingTA,
	|
	// CostPermanentDifference
	|	CASE
	|		WHEN IntangibleAssets.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|			THEN ISNULL(InitialIntangibleAssetsInformation.InitialCostPD, 0)
	|		ELSE ISNULL(IACostBalance.CostPermanentDifference, 0)
	|	END AS CostPermanentDifference,
	|
	// CostTargetFinancingPD
	|	CASE
	|		WHEN IntangibleAssets.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|			THEN 0
	|		ELSE ISNULL(IACostBalance.CostTargetFinancingPD, 0)
	|	END AS CostTargetFinancingPD,
	|
	// CostTemporaryDifference
	|	CASE
	|		WHEN IntangibleAssets.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|			THEN ISNULL(InitialIntangibleAssetsInformation.InitialCostLocalAccounting, 0)
	|					- ISNULL(InitialIntangibleAssetsInformation.InitialCostTA, 0)
	|					- ISNULL(InitialIntangibleAssetsInformation.InitialCostPD, 0)
	|		ELSE ISNULL(IACostBalance.CostTemporaryDifference, 0)
	|	END AS CostTemporaryDifference,
	|
	// CostTargetFinancingTD
	|	CASE
	|		WHEN IntangibleAssets.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|			THEN 0
	|		ELSE ISNULL(IACostBalance.CostTargetFinancingTD, 0)
	|	END AS CostTargetFinancingTD,
	|
	|	ISNULL(-ImpairmentFA.ImpairmentLocalAssetsBalance, 0) AS ImpairmentLocalAssets,
	|   ISNULL(-ImpairmentFA.ImpairmenManBalance, 0) AS ImpairmenMan
	|
	|FROM
	|	Catalog.IntangibleAssets AS IntangibleAssets
	|
	|		LEFT JOIN AccumulationRegister.IntangibleAssetsAmortizationCharge.Balance(
	|				,
	|				Organization = &Organization
	|					AND IntangibleAsset = &IntangibleAsset) AS IntangibleAssetsAmortizationChargeBalance
	|		ON IntangibleAssets.Ref = IntangibleAssetsAmortizationChargeBalance.IntangibleAsset
	|
	|		LEFT JOIN IACostBalance AS IACostBalance
	|		ON IntangibleAssets.Ref = IACostBalance.IntangibleAsset
	|
	|		LEFT JOIN InformationRegister.InitialIntangibleAssetsInformation.SliceLast(
	|				,
	|				Organization = &Organization
	|					AND IntangibleAsset = &IntangibleAsset) AS InitialIntangibleAssetsInformation
	|		ON IntangibleAssets.Ref = InitialIntangibleAssetsInformation.IntangibleAsset
	|
	|		LEFT JOIN InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting.SliceLast(
	|				,
	|				Organization = &Organization
	|					AND IntangibleAsset = &IntangibleAsset) AS IABookkeepingProcedureBookkeepingAndTaxAccounting
	|		ON IntangibleAssets.Ref = IABookkeepingProcedureBookkeepingAndTaxAccounting.IntangibleAsset
	|
	|		LEFT JOIN InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting.SliceLast(
	|				,
	|				Organization = &Organization
	|					AND IntangibleAsset = &IntangibleAsset) AS IntangibleAssetsAccountingProcedureManagementAccounting
	|		ON IntangibleAssets.Ref = IntangibleAssetsAccountingProcedureManagementAccounting.IntangibleAsset
	|
	|		LEFT JOIN AccumulationRegister.ImpairmentFA.Balance(
	|				,
	|				Organization = &Organization
	|					AND NonCurrentAsset = &IntangibleAsset) AS ImpairmentFA
	|		ON IntangibleAssets.Ref = ImpairmentFA.NonCurrentAsset
	|
	|WHERE
	|	IntangibleAssets.Ref = &IntangibleAsset
	|";

	Query = New Query(QueryText);
	Query.SetParameter("IntangibleAsset", IntangibleAsset);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	
	Result = Query.Execute();
	Selection = Result.Select();
	Selection.Next();
	FillPropertyValues(CostAndDepreciation, Selection);

	Return CostAndDepreciation;
	
EndFunction

// Returns information about the cost and depreciation of the nodes and components of the depreciation of the owner's OS.
//
// Parameters:
//  FixedAsset - CatalogRef.Assets	 - The OS is the owner of the nodes and components for which you need to get information.
// 
// Returns:
//  ValueTable - A table with nodes and components and information about their cost
//
Function CostAndDepreciationOfComponentsComponents(FixedAsset) Export

	Organization = Undefined;
	FALocation = FALocation(FixedAsset);
	If FALocation <> Undefined Then
		Organization = FALocation.Organization
	EndIf;
	
	QueryText = NonCurrentAssetsLocalization.QueryTextCostAndDepreciationOfComponentsComponents();
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT DISTINCT
		|	NodesComponents.SubAssetComponent AS SubAssetComponent
		|INTO TTUnitsOfFixedAssets
		|FROM
		|	InformationRegister.SubAssetsComponentsOfDepreciation AS NodesComponents
		|WHERE
		|	NodesComponents.FixedAsset = &FixedAsset
		|
		|INDEX BY
		|	SubAssetComponent
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NodesComponents.SubAssetComponent AS SubAssetComponent
		|INTO NodesComponents
		|FROM
		|	InformationRegister.SubAssetsComponentsOfDepreciation.SliceLast(, SubAssetComponent IN
		|		(SELECT
		|			TTUnitsOfFixedAssets.SubAssetComponent AS SubAssetComponent
		|		FROM
		|			TTUnitsOfFixedAssets AS TTUnitsOfFixedAssets)) AS NodesComponents
		|WHERE
		|	NodesComponents.FixedAsset = &FixedAsset
		|
		|INDEX BY
		|	SubAssetComponent
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NodesComponents.SubAssetComponent AS SubAssetComponent,
		|	CASE
		|		WHEN FixedAssetsAccountingProcedureManagementAccounting.State = VALUE(Enum.FixedAssetsStates.TakenOffBooks)
		|			THEN 0
		|		ELSE ISNULL(-FixedAssetsDepreciationChargeBalance.DepreciationBalance, 0)
		|	END AS Depreciation,
		|	CASE
		|		WHEN FixedAssetsAccountingProcedureManagementAccounting.State = VALUE(Enum.FixedAssetsStates.TakenOffBooks)
		|			THEN 0
		|		ELSE ISNULL(-FixedAssetsDepreciationChargeBalance.DepreciationLocalBalance, 0)
		|	END AS DepreciationLocal,
		|	CASE
		|		WHEN FixedAssetsAccountingProcedureManagementAccounting.State = VALUE(Enum.FixedAssetsStates.TakenOffBooks)
		|			THEN 0
		|		ELSE ISNULL(FACostBalance.CostBalance, 0)
		|	END AS Cost,
		|	CASE
		|		WHEN FixedAssetsAccountingProcedureManagementAccounting.State = VALUE(Enum.FixedAssetsStates.TakenOffBooks)
		|			THEN 0
		|		ELSE ISNULL(FACostBalance.LocalCostBalance, 0)
		|	END AS LocalCost,
		|	CASE
		|		WHEN FixedAssetsAccountingProcedureManagementAccounting.State = VALUE(Enum.FixedAssetsStates.TakenOffBooks)
		|			THEN 0
		|		ELSE ISNULL(-ImpairmentFABalance.ImpairmenManBalance, 0)
		|	END AS ImpairmenMan,
		|	CASE
		|		WHEN FixedAssetsAccountingProcedureManagementAccounting.State = VALUE(Enum.FixedAssetsStates.TakenOffBooks)
		|			THEN 0
		|		ELSE ISNULL(-ImpairmentFABalance.ImpairmentLocalAssetsBalance, 0)
		|	END AS ImpairmentLocalAssets,
		|	CASE
		|		WHEN FixedAssetsAccountingProcedureManagementAccounting.State = VALUE(Enum.FixedAssetsStates.TakenOffBooks)
		|			THEN 0
		|		ELSE ISNULL(FACostBalance.CostBalance, 0)
		|	END - CASE
		|		WHEN FixedAssetsAccountingProcedureManagementAccounting.State = VALUE(Enum.FixedAssetsStates.TakenOffBooks)
		|			THEN 0
		|		ELSE ISNULL(-FixedAssetsDepreciationChargeBalance.DepreciationBalance, 0)
		|	END - CASE
		|		WHEN FixedAssetsAccountingProcedureManagementAccounting.State = VALUE(Enum.FixedAssetsStates.TakenOffBooks)
		|			THEN 0
		|		ELSE ISNULL(-ImpairmentFABalance.ImpairmenManBalance, 0)
		|	END AS NetBookValue,
		|	CASE
		|		WHEN FixedAssetsAccountingProcedureManagementAccounting.State = VALUE(Enum.FixedAssetsStates.TakenOffBooks)
		|			THEN 0
		|		ELSE ISNULL(FACostBalance.LocalCostBalance, 0)
		|	END - CASE
		|		WHEN FixedAssetsAccountingProcedureManagementAccounting.State = VALUE(Enum.FixedAssetsStates.TakenOffBooks)
		|			THEN 0
		|		ELSE ISNULL(-FixedAssetsDepreciationChargeBalance.DepreciationLocalBalance, 0)
		|	END - CASE
		|		WHEN FixedAssetsAccountingProcedureManagementAccounting.State = VALUE(Enum.FixedAssetsStates.TakenOffBooks)
		|			THEN 0
		|		ELSE ISNULL(-ImpairmentFABalance.ImpairmentLocalAssetsBalance, 0)
		|	END AS NetBookValueLocal
		|FROM
		|	NodesComponents AS NodesComponents
		|		LEFT JOIN AccumulationRegister.FixedAssetsDepreciationCharge.Balance(, Organization = &Organization
		|		AND FixedAsset IN
		|			(SELECT
		|				NodesComponents.SubAssetComponent
		|			FROM
		|				NodesComponents AS NodesComponents)) AS FixedAssetsDepreciationChargeBalance
		|		ON NodesComponents.SubAssetComponent = FixedAssetsDepreciationChargeBalance.FixedAsset
		|		LEFT JOIN AccumulationRegister.FACost.Balance(, Organization = &Organization
		|		AND FixedAsset IN
		|			(SELECT
		|				NodesComponents.SubAssetComponent
		|			FROM
		|				NodesComponents AS NodesComponents)) AS FACostBalance
		|		ON NodesComponents.SubAssetComponent = FACostBalance.FixedAsset
		|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(, Organization = &Organization
		|		AND FixedAsset IN
		|			(SELECT
		|				NodesComponents.SubAssetComponent
		|			FROM
		|				NodesComponents AS NodesComponents)) AS FixedAssetsAccountingProcedureManagementAccounting
		|		ON NodesComponents.SubAssetComponent = FixedAssetsAccountingProcedureManagementAccounting.FixedAsset
		|		LEFT JOIN AccumulationRegister.ImpairmentFA.Balance(, Organization = &Organization
		|		AND NonCurrentAsset IN
		|			(SELECT
		|				NodesComponents.SubAssetComponent
		|			FROM
		|				NodesComponents AS NodesComponents)) AS ImpairmentFABalance
		|		ON NodesComponents.SubAssetComponent = ImpairmentFABalance.NonCurrentAsset";
	
	EndIf; 
	
	Query = New Query(QueryText);
	Query.SetParameter("FixedAsset", FixedAsset);
	Query.SetParameter("Organization", Organization);
	
	Result = Query.Execute();
	
	Return Result.Unload();

EndFunction

// Checks that the document is held in the period that corresponds to the document version.
//
// Parameters:
//  Object				 - DocumentObject	 - current document.
//  ThisIsVersion2_4Document - Boolean			 - True if the document belongs to version 2.4.
//  Cancel				 - Boolean			 - The failure of the.
//
Procedure CheckIfDateMatchesAccountingVersion(Object, ThisIsVersion2_4Document, Cancel) Export

	If Not GetFunctionalOption("UseNonCurrentAssets2_4") 
		Or Not GetFunctionalOption("UseNonCurrentAssets2_2") Then 
		Return;
	EndIf;
	
	AccountingStartDate = NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24();
	
	VNAManagementIsUsed_2_4 = (Object.Date >= AccountingStartDate
				Or Object.Date = '000101010000' 
					And CurrentSessionDate() >= AccountingStartDate);
	
	MessageText = Undefined;

	If VNAManagementIsUsed_2_4 And Not ThisIsVersion2_4Document Then
		
		MessageText = NStr("vi = 'Ngày chứng từ phải trước %1 (bắt đầu thời gian ghi nhận tài sản dài hạn 2.4).
                               |Sau ngày này, cần sử dụng chứng từ trong phân hệ ""Tài sản dài hạn"".';
                               |ru = 'Дата документа должна быть до %1 (начало ведения учета внеоборотных активов версии 2.4).
                               |После этой даты необходимо использовать документы, расположенные в разделе ""Внеоборотные активы"".';
                               |en = 'Document date must be before %1 (start date of fixed assets accounting of version 2.4).
                               |After this date, you must use documents from the ""Assets management"" section.'; fa = 'Document date must be before %1 (start date of fixed assets accounting of version 2.4).
                               |After this date, you must use documents from the ""Assets management"" section.';
                               |it = 'La data del documento deve essere prima del %1 (inizio dell''esecuzione dei conti degli attivi non circolanti nella versione 2.4).
                               | Dopo tale data, è necessario utilizzare i documenti dalla sezione ""Attivi non circolanti"".';
                               |pl = 'Data dokumentu powinna być do %1 (początek prowadzenia ewidencji aktywów pozaobrotowych wersji 2.4). 
                               |Po tej dacie należy używać dokumenty, rozmieszczone w rozdziale ""Aktywy nieobrotowe"".';
                               |tr = 'Belgenin tarihi %1''den önce olmalıdır (sürüm 2.4''te duran varlıkların muhasebeleştirilmesinin başlangıcı). 
                               |Bu tarihten sonra ""Duran varlıklar"" bölümünde yer alan belgeler kullanılmalıdır.'");
		MessageText = StrTemplate(MessageText, Format(AccountingStartDate, "DLF=D"));
		
	ElsIf Not VNAManagementIsUsed_2_4 And ThisIsVersion2_4Document  Then
		
		If TypeOf(Object) = Type("DocumentObject.ChangeFixedAssetFinancialDetails2_4")
			Or TypeOf(Object) = Type("DocumentObject.ChangeIntangibleAssetFinancialDetails2_4")
			Or TypeOf(Object) = Type("DocumentObject.EntryOfCapitalAssetsBalance2_4")
				And Object.BusinessOperation <> Enums.BusinessTransactions.OBEntryLeaseContractsARAP Then
				
			// Documents that can be carried out before the start date of accounting version 2.4
			If BegOfDay(Object.Date) < BegOfDay(AccountingStartDate-1) Then
				
				MessageText = NStr("vi = 'Nếu chứng từ đã lập để chuyển sang ghi nhận phiên bản 2.4 thì ngày của chứng từ phải là %1.
	                                   |Trong các trường hợp còn lại ngày chứng từ phải sau %2 (ngày tiến hành tài sản dài hạn phiên bản 2.4).
	                                   |Trước ngày này, cần sử dụng chứng từ trong phân hệ ""Kế toán tài chính"".';
	                                   |ru = 'Если документ оформлен для перехода на учет версии 2.4, то его дата должна быть %1.
	                                   |В остальных случаях дата документа должна быть после %2 (начало ведения учета внеоборотных активов версии 2.4).
	                                   |До этой даты необходимо использовать документы, расположенные в разделе ""Регламентированный учет"".';
	                                   |en = 'If the document is registered to transfer to accounting 2.4, its date must be %1.
	                                   |In other cases the document date must be after %2 (beginning of fixed asset accounting 2.4).
	                                   |Before this date, use documents from the ""Local accounting"" section.'; fa = 'If the document is registered to transfer to accounting 2.4, its date must be %1.
	                                   |In other cases the document date must be after %2 (beginning of fixed asset accounting 2.4).
	                                   |Before this date, use documents from the ""Local accounting"" section.';
	                                   |it = 'Se il documento è rilasciato per la transizione alla versione contabile 2.4, la sua data dovrebbe essere %1.
	                                   | Negli altri casi, la data del documento deve essere successiva al %2(inizio dell''esecuzione dei conti degli attivi non circolanti nella versione 2.4).
	                                   | Fino a tale data, è necessario utilizzare i documenti dalla sezione ""Contabilità regolatoria"".';
	                                   |pl = 'Jeżeli dokument jest sporządzony dla przejścia na ewidencję wersji 2.4, jego data musi być %1.
	                                   |W pozostałych przypadkach data dokumentu musi być po %2 (początek prowadzenia ewidencji aktywów pozaobrotowych wersji 2.4).
	                                   |Do tej daty należy używać dokumenty, rozmieszczone w rozdziale ""Ewidencja reglamentowana"".';
	                                   |tr = 'Belge sürüm 2.4 muhasebesine geçiş için düzenlenmişse, tarihi %1 olmalıdır. 
	                                   |Diğer durumlarda, belgenin tarihi %2''den sonra olmalıdır (sürüm 2.4''te duran varlıkların muhasebeleştirilmesinin başlangıcı). 
	                                   |Bu tarihten önce, ""Yerel Muhasebe"" bölümünde bulunan belgeleri kullanmanız gerekir.'");
				MessageText = StrTemplate(MessageText, Format(AccountingStartDate-1, "DLF=D"), Format(AccountingStartDate, "DLF=D"));
			EndIf; 
			
		Else	
			
			MessageText = NStr("vi = 'Ngày chứng từ phải sau %1 (bắt đầu tiến hành ghi nhận tài sản dài hạn phiên bản 2.4).
	                               |Trước ngày này cần sử dụng các chứng từ nằm trong phân hệ ""Kế toán tài chính"".';
	                               |ru = 'Дата документа должна быть после %1 (начало ведения учета внеоборотных активов версии 2.4).
	                               |До этой даты необходимо использовать документы, расположенные в разделе ""Регламентированный учет"".';
	                               |en = 'Document date must be after %1 (beginning of fixed assets accounting 2.4).
	                               |Before this date, you must use documents from the ""Local accounting"" section.'; fa = 'Document date must be after %1 (beginning of fixed assets accounting 2.4).
	                               |Before this date, you must use documents from the ""Local accounting"" section.';
	                               |it = 'La data del documento deve essere successiva al %1 (inizio dell''esecuzione dei conti degli attivi non circolanti nella versione 2.4).
	                               | Fino a tale data, è necessario utilizzare i documenti dalla sezione ""Contabilità regolatoria"".';
	                               |pl = 'Data dokumentu powinna być po %1 (początek prowadzenia ewidencji pozaobrotowych aktywów wersji 2.4). 
	                               |Do tej dacie należy używać dokumenty, rozmieszczone w rozdziale ""Ewidencja reglamentowana"".';
	                               |tr = 'Belgenin tarihi daha sonra%1 olmalıdır (Duran varlıklar için muhasebenin başlangıcı sürüm 2.4).
	                               |Bu tarihten önce ""Düzenlenmiş muhasebe"" bölümünde yer alan belgelerin kullanılması gerekmektedir.'");
			MessageText = StrTemplate(MessageText, Format(AccountingStartDate, "DLF=D"));
			
		EndIf; 
		
	EndIf; 
	
	If MessageText <> Undefined Then
		Common.MessageToUser(MessageText, Object, "Date",, Cancel); 
	EndIf; 
	
EndProcedure

// verifies that the document is carried out when IA is accounted for by fsb 14.
//
// Parameters:
//  Object - DocumentObject- current document.
//  Cancel - Boolean - The failure of the.
//
Procedure CheckApplicationOfFSB14(Object, Cancel) Export
	
	If Not Object.RecordInLocalAccounting Then
		Return;
	EndIf;

	FSBIsApplied14 = AccountingPoliciesTaxSettingsCached.FSBIsApplied14(
		Object.Organization, EndOfMonth(?(Object.Date <> '00010101', Object.Date, CurrentSessionDate())));
	
	If Not FSBIsApplied14 Then
		MessageText = NStr("vi = 'Hỗ trợ tạo chứng từ chỉ khi ghi nhận TSCĐ vô hình theo chuẩn mực kế toán số 14.';
							|ru = 'Оформление документа поддерживается только при учете НМА по ФСБУ 14.';
							|en = 'You can register the document only if you account for intangible assets by the Russian GAAP (FSBU) 14.'; fa = 'You can register the document only if you account for intangible assets by the Russian GAAP (FSBU) 14.';
							|it = 'Оформление документа поддерживается только при учете НМА по ФСБУ 14.';
							|pl = 'You can register the document only if you account for intangible assets by the Russian GAAP (FSBU) 14.';
							|tr = 'Belge uygulaması yalnızca GMA FAS 14''e göre muhasebeleştirilmesi sırasında desteklenir.'");
		Common.MessageToUser(MessageText, Object, "Date",, Cancel); 
	EndIf;
	
EndProcedure

// Verifies that the document is carried out with the FA and IA accounting in accordance with international accounting standards.
//
// Parameters:
//  Object - DocumentObject- current document.
//  Cancel - Boolean - The failure of the.
//
Procedure CheckIntStandardApplication(Object, Cancel) Export

	If Not Object.RecordInManAccounting Then
		Return;
	EndIf;
	
	AccountingPolicyForFixedAssets = AccountingPoliciesTaxSettingsCached.AccountingPolicyForFixedAssets(
		Object.Organization, EndOfMonth(?(Object.Date <> '00010101', Object.Date, CurrentSessionDate())));
		
	If AccountingPolicyForFixedAssets <> Enums.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards Then
		MessageText = NStr("vi = 'Việc lập chứng từ chỉ được hỗ trợ khi hạch toán TSCĐ hữu hình và TSCĐ vô hình trong kế toán quản trị theo chuẩn mực kế toán quốc tế.';
							|ru = 'Оформление документа поддерживается только при учете ОС и НМА в упр. учете по стандартам международного учета.';
							|en = 'Document creation is supported only when accounting for fixed assets and intangible assets in management accounting according to the financial accounting standards.'; fa = 'Document creation is supported only when accounting for fixed assets and intangible assets in management accounting according to the financial accounting standards.';
							|it = 'Document creation is supported only when accounting for fixed assets and intangible assets in management accounting according to the financial accounting standards.';
							|pl = 'Document creation is supported only when accounting for fixed assets and intangible assets in management accounting according to the financial accounting standards.';
							|tr = 'Uluslararası muhasebe standartlarına göre yönetim muhasebesinde sadece sabit kıymetler ve GMA varlıkların muhasebeleştirilmesinde belge yürütme desteklenmektedir.'");
		Common.MessageToUser(MessageText, Object, "Date",, Cancel); 
	EndIf;
	
EndProcedure

// Defines the organizations for which the closing of the month should be performed together.
//
// Parameters:
//  Period	 - Date - The closing period of the month.
// 
// Returns:
//  Array of Array - List of groups of organizations.
//
Function GroupsOfOrganizationsAboutSiIa(Period) Export
	
	ArrayOSiIa = New Array;
	
	If Not VNAManagementIsUsed_2_4(Period) Then
		Return ArrayOSiIa;
	EndIf;

	CalculationParameters = New Structure;
	CalculationParameters.Insert("Period", Period);
	CalculationParameters.Insert("CompaniesList", New Array);
	NonCurrentAssetsInternal.AddAccountingParametersForNonCurrentAssets(CalculationParameters);
	
	ListOfRequests = New Array;
	
	#Region MovementsBetweenOrganizations
	QueryText =
	"SELECT
	|	DocumentTable.Organization AS Organization,
	|	DocumentTable.CompanyRecipient AS CompanyRecipient,
	|	TabularSection.FixedAsset AS AccountingObject
	|INTO MovementsBetweenOrganizations
	|FROM
	|	Document.FATransfer2_4 AS DocumentTable
	|		LEFT JOIN Document.FATransfer2_4.FA AS TabularSection
	|		ON (TabularSection.Ref = DocumentTable.Ref)
	|WHERE
	|	DocumentTable.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND DocumentTable.Posted
	|	AND DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentTable.Organization,
	|	DocumentTable.CompanyRecipient,
	|	TabularSection.IntangibleAsset
	|FROM
	|	Document.IATransfer2_4 AS DocumentTable
	|		LEFT JOIN Document.IATransfer2_4.IA AS TabularSection
	|		ON (TabularSection.Ref = DocumentTable.Ref)
	|WHERE
	|	DocumentTable.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND DocumentTable.Posted
	|	AND DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice)";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region AccountingProcedure
	QueryText =
	"SELECT
	|	AccountingProcedure.FixedAsset AS AccountingObject,
	|	AccountingProcedure.Organization AS Organization,
	|	AccountingProcedure.DepreciationRecordMethodLA AS DepreciationRecordMethod,
	|	AccountingProcedure.CompanyRecipientOfExpenses AS CompanyRecipient
	|INTO AccountingProcedure
	|FROM
	|	InformationRegister.AccountingProcedureForOSBU.SliceLast(&EndOfPreviousMonth, CorrectionDate = DATETIME(1,1,1)) AS AccountingProcedure
	|WHERE
	|	(AccountingProcedure.TransferExpensesToAnotherCompany
	|			OR NOT AccountingProcedure.DepreciationRecordMethodLA IN (&EmptyWaysToReflectDepreciation))
	|
	|UNION ALL
	|
	|SELECT
	|	AccountingProcedure.FixedAsset AS AccountingObject,
	|	AccountingProcedure.Organization AS Organization,
	|	AccountingProcedure.DepreciationRecordMethodTA AS DepreciationRecordMethod,
	|	AccountingProcedure.CompanyRecipientOfExpenses AS CompanyRecipient
	|FROM
	|	InformationRegister.AccountingProcedureForOSBU.SliceLast(&EndOfPreviousMonth, CorrectionDate = DATETIME(1,1,1)) AS AccountingProcedure
	|WHERE
	|	NOT AccountingProcedure.DepreciationRecordMethodTA IN (&EmptyWaysToReflectDepreciation)
	|
	|UNION ALL
	|
	|SELECT
	|	AccountingProcedure.FixedAsset,
	|	AccountingProcedure.Organization,
	|	AccountingProcedure.DepreciationRecordMethod,
	|	AccountingProcedure.CompanyRecipientOfExpenses
	|FROM
	|	InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(&EndOfPreviousMonth, CorrectionDate = DATETIME(1,1,1)) AS AccountingProcedure
	|WHERE
	|	(AccountingProcedure.TransferExpensesToAnotherCompany
	|			OR NOT AccountingProcedure.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation))
	|
	|UNION ALL
	|
	|SELECT
	|	AccountingProcedure.FixedAsset,
	|	AccountingProcedure.Organization,
	|	AccountingProcedure.DepreciationRecordMethod,
	|	AccountingProcedure.CompanyRecipientOfExpenses
	|FROM
	|	InformationRegister.FixedAssetsAccountingProcedureManagementAccounting AS AccountingProcedure
	|WHERE
	|	AccountingProcedure.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND AccountingProcedure.CorrectionDate = DATETIME(1,1,1)
	|	AND (AccountingProcedure.TransferExpensesToAnotherCompany
	|			OR NOT AccountingProcedure.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation))
	|
	|UNION ALL
	|
	|SELECT
	|	AccountingProcedure.IntangibleAsset,
	|	AccountingProcedure.Organization,
	|	AccountingProcedure.DepreciationRecordMethodLA,
	|	AccountingProcedure.CompanyRecipientOfExpenses
	|FROM
	|	InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting.SliceLast(&EndOfPreviousMonth, ) AS AccountingProcedure
	|WHERE
	|	(AccountingProcedure.TransferExpensesToAnotherCompany
	|			OR NOT AccountingProcedure.DepreciationRecordMethodLA IN (&EmptyWaysToReflectDepreciation))
	|
	|UNION ALL
	|
	|SELECT
	|	AccountingProcedure.IntangibleAsset,
	|	AccountingProcedure.Organization,
	|	AccountingProcedure.DepreciationRecordMethodTA,
	|	AccountingProcedure.CompanyRecipientOfExpenses
	|FROM
	|	InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting.SliceLast(&EndOfPreviousMonth, ) AS AccountingProcedure
	|WHERE
	|	NOT AccountingProcedure.DepreciationRecordMethodTA IN (&EmptyWaysToReflectDepreciation)
	|
	|UNION ALL
	|
	|SELECT
	|	AccountingProcedure.IntangibleAsset,
	|	AccountingProcedure.Organization,
	|	AccountingProcedure.DepreciationRecordMethod,
	|	AccountingProcedure.CompanyRecipientOfExpenses
	|FROM
	|	InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting.SliceLast(&EndOfPreviousMonth, ) AS AccountingProcedure
	|WHERE
	|	(AccountingProcedure.TransferExpensesToAnotherCompany
	|			OR NOT AccountingProcedure.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation))
	|
	|UNION ALL
	|
	|SELECT
	|	AccountingProcedure.IntangibleAsset,
	|	AccountingProcedure.Organization,
	|	AccountingProcedure.DepreciationRecordMethod,
	|	AccountingProcedure.CompanyRecipientOfExpenses
	|FROM
	|	InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting AS AccountingProcedure
	|WHERE
	|	AccountingProcedure.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND (AccountingProcedure.TransferExpensesToAnotherCompany
	|			OR NOT AccountingProcedure.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation))
	|
	|INDEX BY
	|	DepreciationRecordMethod";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region WaysToReflectDepreciation
	QueryText =
	"SELECT
	|	AccountingProcedure.DepreciationRecordMethod AS DepreciationRecordMethod
	|INTO AccountingProcedureWithMethodOfReflectingExpenses
	|FROM
	|	AccountingProcedure AS AccountingProcedure
	|WHERE
	|	AccountingProcedure.DepreciationRecordMethod <> UNDEFINED
	|		AND AccountingProcedure.DepreciationRecordMethod <> UNDEFINED
	|
	|INDEX BY
	|	DepreciationRecordMethod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableDepreciation.Ref AS DepreciationRecordMethod,
	|	TableDepreciation.CompanyRecipientOfExpenses AS CompanyRecipient
	|INTO WaysToReflectDepreciation
	|FROM
	|	Document.ChangeFixedAssetFinancialDetails2_4.Depreciation AS TableDepreciation
	|WHERE
	|	TableDepreciation.Ref IN
	|			(SELECT
	|				WaysToReflectDepreciation.DepreciationRecordMethod
	|			FROM
	|				AccountingProcedureWithMethodOfReflectingExpenses AS WaysToReflectDepreciation)
	|	AND TableDepreciation.TransferExpensesToAnotherCompany
	|
	|UNION ALL
	|
	|SELECT
	|	TableDepreciation.Ref,
	|	TableDepreciation.CompanyRecipientOfExpenses
	|FROM
	|	Document.ChangeFixedAssetFinancialDetails2_4.DepreciationAllowance AS TableDepreciation
	|WHERE
	|	TableDepreciation.Ref IN
	|			(SELECT
	|				WaysToReflectDepreciation.DepreciationRecordMethod
	|			FROM
	|				AccountingProcedureWithMethodOfReflectingExpenses AS WaysToReflectDepreciation)
	|	AND TableDepreciation.TransferExpensesToAnotherCompany
	|
	|UNION ALL
	|
	|SELECT
	|	TableDepreciation.Ref,
	|	TableDepreciation.CompanyRecipientOfExpenses
	|FROM
	|	Document.ChangeIntangibleAssetFinancialDetails2_4.Depreciation AS TableDepreciation
	|WHERE
	|	TableDepreciation.Ref IN
	|			(SELECT
	|				WaysToReflectDepreciation.DepreciationRecordMethod
	|			FROM
	|				AccountingProcedureWithMethodOfReflectingExpenses AS WaysToReflectDepreciation)
	|	AND TableDepreciation.TransferExpensesToAnotherCompany";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DepreciationPackages
	QueryText =
	"SELECT
	|	DataTable.Organization AS Organization,
	|	DataTable.CompanyRecipient AS CompanyRecipient,
	|	DataTable.AccountingObject AS AccountingObject
	|INTO DepreciationPackages
	|FROM
	|	MovementsBetweenOrganizations AS DataTable
	|
	|UNION ALL
	|
	|SELECT
	|	DataTable.Organization,
	|	DataTable.CompanyRecipient,
	|	DataTable.AccountingObject
	|FROM
	|	AccountingProcedure AS DataTable
	|WHERE
	|	(DataTable.DepreciationRecordMethod = UNDEFINED
	|			OR DataTable.DepreciationRecordMethod = UNDEFINED)
	|
	|UNION ALL
	|
	|SELECT
	|	DataTable.Organization,
	|	WaysToReflectDepreciation.CompanyRecipient,
	|	DataTable.AccountingObject
	|FROM
	|	AccountingProcedure AS DataTable
	|		INNER JOIN WaysToReflectDepreciation AS WaysToReflectDepreciation
	|		ON (WaysToReflectDepreciation.DepreciationRecordMethod = DataTable.DepreciationRecordMethod)
	|WHERE
	|	DataTable.DepreciationRecordMethod <> UNDEFINED
	|	AND DataTable.DepreciationRecordMethod <> UNDEFINED
	|
	|INDEX BY
	|	AccountingObject,
	|	Organization";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region ListOfAccountingObjects
	QueryText =
	"SELECT
	|	FixedAssetsAccountingProcedure.FixedAsset AS AccountingObject
	|INTO ListOfAccountingObjects
	|FROM
	|	InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
	|			&EndOfPreviousMonth,
	|			CorrectionDate = DATETIME(1,1,1)
	|			AND (Organization, FixedAsset) IN
	|				(SELECT
	|					DepreciationPackages.Organization,
	|					DepreciationPackages.AccountingObject
	|				FROM
	|					DepreciationPackages AS DepreciationPackages)) AS FixedAssetsAccountingProcedure
	|
	|WHERE
	|	FixedAssetsAccountingProcedure.AccrueDepreciationOrAmortization
	|
	|UNION ALL
	|
	|SELECT
	|	FixedAssetsAccountingProcedure.FixedAsset AS AccountingObject
	|FROM
	|	InformationRegister.FixedAssetsAccountingProcedureManagementAccounting AS FixedAssetsAccountingProcedure
	|
	|WHERE
	|	FixedAssetsAccountingProcedure.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND FixedAssetsAccountingProcedure.Active
	|
	|	AND FixedAssetsAccountingProcedure.AccrueDepreciationOrAmortization
	|
	|	AND VALUETYPE(FixedAssetsAccountingProcedure.Recorder) IN (
	|				TYPE(Document.FixedAssetsInitialRecognition2_4),
	|				TYPE(Document.SplitFixedAssets),
	|				TYPE(Document.MergeOfFixedAssets))
	|
	|	AND (FixedAssetsAccountingProcedure.Organization, FixedAssetsAccountingProcedure.FixedAsset) IN
	|				(SELECT
	|					DepreciationPackages.Organization,
	|					DepreciationPackages.AccountingObject
	|				FROM
	|					DepreciationPackages AS DepreciationPackages)
	|
	|UNION ALL
	|
	|SELECT
	|	FixedAssetsAccountingProcedure.FixedAsset AS AccountingObject
	|FROM
	|	InformationRegister.AccountingProcedureForOSBU.SliceLast(
	|			&EndOfPreviousMonth,
	|			CorrectionDate = DATETIME(1,1,1)
	|			AND (Organization, FixedAsset) IN
	|				(SELECT
	|					DepreciationPackages.Organization,
	|					DepreciationPackages.AccountingObject
	|				FROM
	|					DepreciationPackages AS DepreciationPackages)) AS FixedAssetsAccountingProcedure
	|WHERE
	|	(FixedAssetsAccountingProcedure.DepreciationAccrualAccounting
	|		OR FixedAssetsAccountingProcedure.DepreciationAccrualTaxAccounting)
	|
	|UNION ALL
	|
	|SELECT
	|	FixedAssetsAccountingProcedure.FixedAsset AS AccountingObject
	|FROM
	|	InformationRegister.AccountingProcedureForOSBU AS FixedAssetsAccountingProcedure
	|
	|WHERE
	|	FixedAssetsAccountingProcedure.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND FixedAssetsAccountingProcedure.Active
	|
	|	AND (FixedAssetsAccountingProcedure.DepreciationAccrualAccounting
	|		OR FixedAssetsAccountingProcedure.DepreciationAccrualTaxAccounting)
	|
	|	AND VALUETYPE(FixedAssetsAccountingProcedure.Recorder) IN (
	|				TYPE(Document.FixedAssetsInitialRecognition2_4),
	|				TYPE(Document.SplitFixedAssets),
	|				TYPE(Document.MergeOfFixedAssets))
	|
	|	AND (FixedAssetsAccountingProcedure.Organization, FixedAssetsAccountingProcedure.FixedAsset) IN
	|				(SELECT
	|					DepreciationPackages.Organization,
	|					DepreciationPackages.AccountingObject
	|				FROM
	|					DepreciationPackages AS DepreciationPackages)
	|
	|UNION ALL
	|
	|SELECT
	|	IntangibleAssetsAccountingProcedure.IntangibleAsset AS AccountingObject
	|FROM
	|	InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting.SliceLast(
	|			&EndOfPreviousMonth,
	|			(Organization, IntangibleAsset) IN
	|				(SELECT
	|					DepreciationPackages.Organization,
	|					DepreciationPackages.AccountingObject
	|				FROM
	|					DepreciationPackages AS DepreciationPackages)) AS IntangibleAssetsAccountingProcedure
	|
	|WHERE
	|	IntangibleAssetsAccountingProcedure.AccrueDepreciationOrAmortization
	|
	|UNION ALL
	|
	|SELECT
	|	IntangibleAssetsAccountingProcedure.IntangibleAsset AS AccountingObject
	|FROM
	|	InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting AS IntangibleAssetsAccountingProcedure
	|
	|WHERE
	|	IntangibleAssetsAccountingProcedure.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND IntangibleAssetsAccountingProcedure.Active
	|
	|	AND IntangibleAssetsAccountingProcedure.AccrueDepreciationOrAmortization
	|
	|	AND VALUETYPE(IntangibleAssetsAccountingProcedure.Recorder) = TYPE(Document.IntangibleAssetsInitialRecognition2_4)
	|
	|	AND (IntangibleAssetsAccountingProcedure.Organization, IntangibleAssetsAccountingProcedure.IntangibleAsset) IN
	|				(SELECT
	|					DepreciationPackages.Organization,
	|					DepreciationPackages.AccountingObject
	|				FROM
	|					DepreciationPackages AS DepreciationPackages)
	|
	|UNION ALL
	|
	|SELECT
	|	IntangibleAssetsAccountingProcedure.IntangibleAsset AS AccountingObject
	|FROM
	|	InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting.SliceLast(
	|			&EndOfPreviousMonth,
	|			(Organization, IntangibleAsset) IN
	|				(SELECT
	|					DepreciationPackages.Organization,
	|					DepreciationPackages.AccountingObject
	|				FROM
	|					DepreciationPackages AS DepreciationPackages)) AS IntangibleAssetsAccountingProcedure
	|WHERE
	|	(IntangibleAssetsAccountingProcedure.DepreciationAccrualAccounting
	|		OR IntangibleAssetsAccountingProcedure.DepreciationAccrualTaxAccounting)
	|
	|UNION ALL
	|
	|SELECT
	|	IntangibleAssetsAccountingProcedure.IntangibleAsset AS AccountingObject
	|FROM
	|	InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting AS IntangibleAssetsAccountingProcedure
	|
	|WHERE
	|	IntangibleAssetsAccountingProcedure.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND IntangibleAssetsAccountingProcedure.Active
	|
	|	AND (IntangibleAssetsAccountingProcedure.DepreciationAccrualAccounting
	|		OR IntangibleAssetsAccountingProcedure.DepreciationAccrualTaxAccounting)
	|
	|	AND VALUETYPE(IntangibleAssetsAccountingProcedure.Recorder) = TYPE(Document.IntangibleAssetsInitialRecognition2_4)
	|
	|	AND (IntangibleAssetsAccountingProcedure.Organization, IntangibleAssetsAccountingProcedure.IntangibleAsset) IN
	|				(SELECT
	|					DepreciationPackages.Organization,
	|					DepreciationPackages.AccountingObject
	|				FROM
	|					DepreciationPackages AS DepreciationPackages)
	|
	|INDEX BY
	|	AccountingObject";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region Selection
	QueryText =
	"SELECT DISTINCT
	|	DataTable.Organization AS Organization,
	|	DataTable.CompanyRecipient AS CompanyRecipient
	|FROM
	|	DepreciationPackages AS DataTable
	|WHERE
	|	DataTable.AccountingObject IN
	|			(SELECT
	|				ListOfAccountingObjects.AccountingObject
	|			FROM
	|				ListOfAccountingObjects AS ListOfAccountingObjects)";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query = New Query(QueryText);
	FixedAssetDepreciationCalculation.SetQueryParametersForCalculatingDepreciation(Query, CalculationParameters);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	NumberOfGroup  = -1;
	
	While Selection.Next() Do
		
		NumberOfGroup = NumberOfGroup + 1;
		ArrayOSiIa.Add(New Array);
		
		ArrayOSiIa[NumberOfGroup].Add(Selection.Organization);
		ArrayOSiIa[NumberOfGroup].Add(Selection.CompanyRecipient);
		
	EndDo;

	Return ArrayOSiIa;
	
EndFunction

// See ReportsOptionsOverridable.CustomizeReportsOptions.
//
Procedure CustomizeReportsOptions(Settings) Export

	NonCurrentAssetsLocalization.CustomizeReportsOptions(Settings);
	
	ComplianceCAAccountingIsKept = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	
	Reports.FixedAssetsStatementManagementAccounting.CustomizeReportOptions(Settings, ComplianceCAAccountingIsKept);
	Reports.SpreadsheetOfIntangibleAssetsAndRDExpenses.CustomizeReportOptions(Settings, ComplianceCAAccountingIsKept);
	Reports.StatementCalculationOfAssetsDepreciation.CustomizeReportOptions(Settings, ComplianceCAAccountingIsKept);
	Reports.StatementCalculationOfIntangibleAssetsAmortization.CustomizeReportOptions(Settings, ComplianceCAAccountingIsKept);
	Reports.FixedAssetRegister.CustomizeReportOptions(Settings, ComplianceCAAccountingIsKept);
	Reports.AssetsLeasedOut.CustomizeReportOptions(Settings);
	Reports.ExpenseStructureByFixedAssets.CustomizeReportOptions(Settings);
	
	#Region AssetCard
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.AssetCard);
	DescriptionOfReport.Enabled = False;
	#EndRegion
	
	Reports.ControlOfAccuracyOfAssetPopulation.CustomizeReportOptions(Settings);

	Reports.FixedAssetsWithImpairment.CustomizeReportOptions(Settings);

EndProcedure

// Determines whether the upgrade to version 2.4 is complete.
//
// Parameters:
//  Period - Date - parameters of the stage event handler.
//  CompaniesList - Array of CatalogRef.Companies - 
// 
// Returns:
//  Boolean - True if the transition is complete.
//
Function TransitionToVNAHasBeenCompleted24(Period, CompaniesList) Export

	If Not VNAManagementIsUsed_2_4(Period)
		Or Not GetFunctionalOption("UseNonCurrentAssets2_2") Then
		Return True;
	EndIf;
	
	StageState = MonthEndTransactionsServer.DetermineStateOfCalculationSteps(
						NonCurrentAssetsLocalization.OperationOfSwitchingToFixedAndIntangibleAssets2_4(),
						Period, 
						CompaniesList,
						False,
						False);
						
	Return StageState <> Enums.StatesOfMonthEndClosingOperations.NotCompleted;

EndFunction

// Specifies the settings for receiving data in the request, which contains access two versions of the account.
//
// Parameters:
//  BeginOfPeriod - Date - the beginning of the period.
//  EndOfPeriod - Date - the beginning of the period.
// 
// Returns:
//  Structure - Parameters for receiving data in the request.
//
Function ParametersForGettingDataFromTwoAccountingVersions(BeginOfPeriod, EndOfPeriod) Export

	BeginOfPeriod22 = BeginOfPeriod;
	BeginOfPeriod24 = BeginOfPeriod;
	EndOfPeriod22 = EndOfPeriod;
	EndOfPeriod24 = EndOfPeriod;
	
	TheBeginningOfTheAccounting24 = NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24();
	UseNonCurrentAssets2_2 = Constants.UseNonCurrentAssets2_2.Get();
	UseNonCurrentAssets2_4 = Constants.UseNonCurrentAssets2_4.Get();
	
	Version22IsUsed =
		UseNonCurrentAssets2_2
		And (Not ValueIsFilled(BeginOfPeriod)
			Or BeginOfPeriod < TheBeginningOfTheAccounting24
			Or Not UseNonCurrentAssets2_4);
			
	Version24IsUsed =
		UseNonCurrentAssets2_4
		And (Not ValueIsFilled(EndOfPeriod)
			Or EndOfPeriod > TheBeginningOfTheAccounting24);
			
	If Version22IsUsed And Version24IsUsed Then
		EndOfPeriod22 = TheBeginningOfTheAccounting24 - 1;
		BeginOfPeriod24 = TheBeginningOfTheAccounting24;
	EndIf; 

	DataGetParameters = New Structure;
	DataGetParameters.Insert("Version22IsUsed", Version22IsUsed);
	DataGetParameters.Insert("Version24IsUsed", Version24IsUsed);
	DataGetParameters.Insert("BeginOfPeriod22", BeginOfPeriod22);
	DataGetParameters.Insert("EndOfPeriod22", EndOfPeriod22);
	DataGetParameters.Insert("BeginOfPeriod24", BeginOfPeriod24);
	DataGetParameters.Insert("EndOfPeriod24", EndOfPeriod24);
	
	Return DataGetParameters;
	
EndFunction

// Allows you to determine whether the table part of the document contains rows with the same accounting objects.
//  When duplicates are found, it generates messages to the user.
//
// Parameters:
//  Object - DocumentObject - Document.
//  TabularSectionName - String - Name of the table part to search for duplicates in.
//  AttributeName - String - Name of the PM prop.
//  Cancel - Boolean - Indicates that further processing was refused.
//  MessageTemplate - String - The message template to be used.
//  ValueFormat - String - Value format: Month, Quarter.
//
Procedure CheckAbsenceOfDuplicatesInTablePart(Object, TabularSectionName, AttributeName, Cancel, MessageTemplate = Undefined, ValueFormat = Undefined) Export
	
	If MessageTemplate = Undefined Then
		If TabularSectionName = "FA" Then
			MessageTemplate = NStr("vi = 'Tài sản cố định ""%1"" đã được chọn trên dòng  %2.';
									|ru = 'Основное средство ""%1"" уже выбрано в строке %2.';
									|en = 'Asset ""%1"" is already selected in line %2.'; fa = 'Asset ""%1"" is already selected in line %2.';
									|it = 'Capitale fisso ""%1"" già selezionato nella riga %2.';
									|pl = 'Środek trwały ""%1"" jest już wybrany w wierszu %2.';
									|tr = 'Sabit kıymet ""%1''''%2satırında zaten seçili .'");
		ElsIf TabularSectionName = "IA" Then
			MessageTemplate = NStr("vi = 'Tài sản cố định vô hình ""%1""đã được chọn trên dòng  %2.';
									|ru = 'Нематериальный актив ""%1"" уже выбран в строке %2.';
									|en = 'Intangible asset ""%1"" is already selected in line %2.'; fa = 'Intangible asset ""%1"" is already selected in line %2.';
									|it = 'Bene imateriale ""%1"" già selezionato nella riga %2.';
									|pl = 'Wartość niematerialna ""%1"" jest już wybrana w wierszu %2.';
									|tr = 'Maddi olmayan varlık ''''%1'''' %2satırında zaten seçili .'");
		Else
			MessageTemplate = NStr("vi = 'Giá trị ""%1"" đã được chọn trên dòng %2.';
									|ru = 'Значение ""%1"" уже выбрано в строке %2.';
									|en = 'Value ""%1"" is already selected in line %2.'; fa = 'Value ""%1"" is already selected in line %2.';
									|it = 'Valore ""%1"" già selezionato nella riga %2.';
									|pl = 'Wartość ""%1"" jest już wybrana w wierszu %2.';
									|tr = '""%1"" değeri %2 satırında zaten seçili.'");
		EndIf;
	EndIf; 
	
	ListOfObjects = New Map;
	For Each RowData In Object[TabularSectionName] Do
		
		If Not ValueIsFilled(RowData[AttributeName]) Then
			Continue;
		EndIf;
		
		InitialString = ListOfObjects.Get(RowData[AttributeName]);
		If InitialString = Undefined Then
			ListOfObjects.Insert(RowData[AttributeName], RowData.LineNumber);
			Continue;
		EndIf; 
		
		If Upper(ValueFormat) = "MONTH"
			Or Upper(ValueFormat) = "QUARTER" Then
			StringValue_ = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(RowData[AttributeName], ValueFormat);
		Else
			StringValue_ = RowData[AttributeName];
		EndIf;
		
		MessageText = StrTemplate(MessageTemplate, StringValue_, Format(InitialString, "NG="));
		Field = CommonClientServer.PathToTabularSection(TabularSectionName, RowData.LineNumber, AttributeName);
		Common.MessageToUser(MessageText, Object, Field, "", Cancel);
	
	EndDo; 
	
EndProcedure

// Determines whether the operational object is accepted for accounting.
//
// Parameters:
//  Ref	 - CatalogRef.Assets	 - Object of operation.
// 
// Returns:
//  Boolean - True if taken into account.
//
Function ObjectOfOperationIsTakenIntoAccount(Ref) Export

	InitialInformation = Catalogs.Assets.InitialInformation(Ref);
	PostedInFinancialAccounting = 
		InitialInformation.StateOfTheUU = Enums.FixedAssetsStates.Recognized_ 
		Or InitialInformation.BUState = Enums.FixedAssetsStates.Recognized_
		Or InitialInformation.BUState = Enums.FixedAssetsStates.EnteredInOffBalanceAccounting
		Or InitialInformation.StateTa = Enums.FixedAssetsStates.Recognized_;
	
	Return PostedInFinancialAccounting

EndFunction

// Defines configuration objects whose manager modules have a procedure for adding Report commands
// describing commands for opening contextual reports.
// For the syntax of the Add Report Commands procedure, see the documentation.
//
// Parameters:
//   Objects - Array of MetadataObject - metadata objects with report commands.
//
Procedure DefineObjectsWithReportCommands(Objects) Export
	
	Objects.Add(Metadata.Catalogs.IntangibleAssets);
	
	Objects.Add(Metadata.Documents.IntangibleAssetsAmortizationCharge2_4);
	Objects.Add(Metadata.Documents.FixedAssetsDepreciationCharge2_4);
	Objects.Add(Metadata.Documents.EntryOfCapitalAssetsBalance2_4);
	Objects.Add(Metadata.Documents.OBEntrySubAssetsAndComponentsOfDepreciation);
	Objects.Add(Metadata.Documents.ReturnAssetsFromLeasee2_4);
	Objects.Add(Metadata.Documents.ReturnLeasedAssets);
	Objects.Add(Metadata.Documents.IntangibleAssetsOperatingTime);
	Objects.Add(Metadata.Documents.IntangibleAssetsOperatingTime);
	Objects.Add(Metadata.Documents.ChangeIntangibleAssetFinancialDetails2_4);
	Objects.Add(Metadata.Documents.ChangeFixedAssetFinancialDetails2_4);
	Objects.Add(Metadata.Documents.IntangibleAssetsPhysicalCount);
	Objects.Add(Metadata.Documents.FixedAssetsPhysicalCount);
	Objects.Add(Metadata.Documents.IntangibleAssetsCostAndAmortizationAdjustment);
	Objects.Add(Metadata.Documents.FixedAssetCostAndDepreciationAdjustment);
	Objects.Add(Metadata.Documents.FixedAssetsCostAdditions2_4);
	Objects.Add(Metadata.Documents.ImpairmentFA);
	Objects.Add(Metadata.Documents.MergeOfFixedAssets);
	Objects.Add(Metadata.Documents.AllocateVariancesToFixedAssetCost);
	Objects.Add(Metadata.Documents.ProvideAssetsToLeasee2_4);
	Objects.Add(Metadata.Documents.IATransfer2_4);
	Objects.Add(Metadata.Documents.FATransfer2_4);
	Objects.Add(Metadata.Documents.IARevaluation2_4);
	Objects.Add(Metadata.Documents.FARevaluation2_4);
	Objects.Add(Metadata.Documents.PreparingForIntangibleAssetSale2_4);
	Objects.Add(Metadata.Documents.PreparingForFixedAssetSale2_4);
	Objects.Add(Metadata.Documents.ReceiveLeasedAssets);
	Objects.Add(Metadata.Documents.IntangibleAssetsInitialRecognition2_4);
	Objects.Add(Metadata.Documents.FixedAssetsInitialRecognition2_4);
	Objects.Add(Metadata.Documents.RecognizeSubAssetsComponentsOfDepreciation);
	Objects.Add(Metadata.Documents.SplitFixedAssets);
	Objects.Add(Metadata.Documents.DisposeIntangibleAssets2_4);
	Objects.Add(Metadata.Documents.DisposeFixedAssets2_4);
	Objects.Add(Metadata.Documents.IntangibleAssetImprovement);
	
	Objects.Add(Metadata.DataProcessors.JournalOfIADocuments2_4);
	Objects.Add(Metadata.DataProcessors.FADocumentLog2_4);
	
	NonCurrentAssetsLocalization.DefineObjectsWithReportCommands(Objects);
	
EndProcedure

// Adds documents from the VNA subsystem to the log.
//
// Parameters:
//  BusinessTransactionsAndDocuments	 - See TMCommonUse.NewTableBusinessOperationsAndDocuments
//
Procedure CompleteDescriptionOfOperationsAndDocumentTypesForProcurementDocumentLog(BusinessTransactionsAndDocuments) Export

	NonCurrentAssetsLocalization.CompleteDescriptionOfOperationsAndDocumentTypesForProcurementDocumentLog(BusinessTransactionsAndDocuments);
	
EndProcedure

// Returns the operating systems that are accepted for accounting.
//
// Parameters:
//  PrimaryFacilityOrList	 - Array, CatalogRef.Assets	 - Fixed assets that need to be checked for accounting.
//  Period						 - Date											 - The date on which the OS should be accepted for accounting.
//  StateAccepted				 - Array										 - List of States in which the OS is considered accepted for accounting.
// 
// Returns:
//  Array - Operating systems that are accepted for accounting.
//
Function ReturnFAAcceptedForAccounting(PrimaryFacilityOrList, Period, StateAccepted = Undefined) Export

	If Not ValueIsFilled(PrimaryFacilityOrList) Then
		Return New Array;
	EndIf;
	
	QueryText = NonCurrentAssetsLocalization.QueryTextFAAcceptedForAccounting();
	
	If QueryText = Undefined Then
		QueryText = 
		"SELECT
		|	FALocation.FixedAsset AS FixedAsset
		|FROM
		|	InformationRegister.FALocation.SliceLast(&Period, CorrectionDate = DATETIME(1,1,1) AND FixedAsset IN (&ListOfFA)) AS FALocation
		|
		|		INNER JOIN InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
		|				&Period, 
		|				CorrectionDate = DATETIME(1,1,1)
		|					AND FixedAsset IN (&ListOfFA)) AS FixedAssetsAccountingProcedureManagementAccounting
		|		ON FALocation.FixedAsset = FixedAssetsAccountingProcedureManagementAccounting.FixedAsset
		|			AND FALocation.Organization = FixedAssetsAccountingProcedureManagementAccounting.Organization
		|WHERE
		|	FixedAssetsAccountingProcedureManagementAccounting.State = VALUE(Enum.FixedAssetsStates.Recognized_)
		|
		|ORDER BY
		|	FALocation.FixedAsset.Description,
		|	FALocation.FixedAsset.AssetID";
	EndIf; 
	
	Query = New Query(QueryText);
	Query.SetParameter("Period", Period);
	
	If StateAccepted = Undefined Then
		StateAccepted = Enums.FixedAssetsStates.Recognized_;
	EndIf; 
	Query.SetParameter("StateAccepted", StateAccepted);
	
	ListOfFA = ?(TypeOf(PrimaryFacilityOrList) = Type("Array"), PrimaryFacilityOrList, CommonClientServer.ValueInArray(PrimaryFacilityOrList));
	Query.SetParameter("ListOfFA", ListOfFA);
	
	Return Query.Execute().Unload().UnloadColumn("FixedAsset");

EndFunction

// Returns the operating systems that are accepted for accounting.
//
// Parameters:
//  IAOrList	 - Array, CatalogRef.IntangibleAssets	 - IA for which you need to check the acceptance of accounting.
//  Period						 - Date											 - The date on which the IA should be accepted for accounting.
// 
// Returns:
//  Array - IA that are accepted for accounting.
//
Function ReturnIAAcceptedForAccounting(IAOrList, Period) Export

	If Not ValueIsFilled(IAOrList) Then
		Return New Array;
	EndIf;
	
	QueryText = NonCurrentAssetsLocalization.QueryTextIAAcceptedForAccounting();
	
	If QueryText = Undefined Then
		QueryText = 
		"SELECT
		|	IntangibleAssetsRegistrationPlace.IntangibleAsset AS IntangibleAsset
		|FROM
		|	InformationRegister.IntangibleAssetsRegistrationPlace.SliceLast(&Period, IntangibleAsset IN (&ListOfIA)) AS IntangibleAssetsRegistrationPlace
		|		INNER JOIN InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting.SliceLast(&Period, IntangibleAsset IN (&ListOfIA)) AS IntangibleAssetsAccountingProcedureManagementAccounting
		|		ON IntangibleAssetsRegistrationPlace.IntangibleAsset = IntangibleAssetsAccountingProcedureManagementAccounting.IntangibleAsset
		|			AND IntangibleAssetsRegistrationPlace.Organization = IntangibleAssetsAccountingProcedureManagementAccounting.Organization
		|WHERE
		|	IntangibleAssetsAccountingProcedureManagementAccounting.State = VALUE(Enum.IntangibleAssetsStates.PostedInFinancialAccounting)
		|
		|ORDER BY
		|	IntangibleAssetsRegistrationPlace.IntangibleAsset.Description,
		|	IntangibleAssetsRegistrationPlace.IntangibleAsset.Code";
	EndIf; 
	
	Query = New Query(QueryText);
	Query.SetParameter("Period", Period);
	
	ListOfIA = ?(TypeOf(IAOrList) = Type("Array"), IAOrList, CommonClientServer.ValueInArray(IAOrList));
	Query.SetParameter("ListOfIA", ListOfIA);
	
	Return Query.Execute().Unload().UnloadColumn("IntangibleAsset");

EndFunction

// Deletes objects that do not match the selection from the array.
//
// Parameters:
//  ObjectsArray	 - Array	 - An array from which you want to delete operational objects.
//  PickingParameters - Structure - Selection parameters.
//
// Returns:
// 	Array of CatalogRef.Assets - deleted links. 
Function DeleteObjectsThatDoNotMatchSelection(ObjectsArray, PickingParameters) Export

	RightsSettings = New Structure;
	
	RightsSettings.Insert(
		"ThereIsRightToRead_LocationOfFA", 
		AccessRight("Read", Metadata.InformationRegisters.FALocation));

	RightsSettings.Insert(
		"ThereIsRightToRead_OrderOfAccountingOfOSU", 
		AccessRight("Read", Metadata.InformationRegisters.FixedAssetsAccountingProcedureManagementAccounting));

	RightsSettings.Insert(
		"ThereIsRightToRead_OSBUAccountingProcedure", 
		AccessRight("Read", Metadata.InformationRegisters.AccountingProcedureForOSBU));

	RightsSettings.Insert(
		"ThereIsRightToRead_FAAccountingProcedure", 
		AccessRight("Read", Metadata.InformationRegisters.FixedAssetsAccountingProcedure));

	RightsSettings.Insert(
		"ThereIsRightToRead_OSUUDepreciationParameters", 
		AccessRight("Read", Metadata.InformationRegisters.FixedAssetDepreciationParametersManagementAccounting));

	RightsSettings.Insert(
		"ThereIsRightToRead_OSBUDepreciationParameters", 
		AccessRight("Read", Metadata.InformationRegisters.OSBUDepreciationParameters));

	RightsSettings.Insert(
		"ThereIsRightToRead_InitialFAInformation", 
		AccessRight("Read", Metadata.InformationRegisters.InitialFixedAssetsInformation));

	RightsSettings.Insert(
		"ThereIsRightToRead_RentedFA", 
		AccessRight("Read", Metadata.InformationRegisters.LeasedAsset));

	ChoiceParameters = Catalogs.Assets.GetChoiceParameters(PickingParameters, RightsSettings);
	DescriptionOfSelectionRequest = Catalogs.Assets.DescriptionOfItemSelectionRequest(ChoiceParameters, RightsSettings, False, True);
	
	If DescriptionOfSelectionRequest.RequiredTables.Count() <> 0 Then
	
		ListOfRequests = New Array();
		
		QueryText =
		"SELECT ALLOWED
		|	CatalogData.Ref AS Ref,
		|	CatalogData.Description AS Description,
		|	CatalogData.AssetID AS AssetID,
		|	CatalogData.OSGroup AS OSGroup,
		|	CatalogData.FixedAssetsGroupFinancialAccounting AS FixedAssetsGroupFinancialAccounting,
		|	CatalogData.OSType AS OSType,
		|	CatalogData.DateOfProduction AS DateOfProduction,
		|	CatalogData.DateOfLastEdit AS DateOfLastEdit,
		|	CatalogData.ManufaturerNumber AS ManufaturerNumber,
		|	CatalogData.RegisteredInPlatonSystemRegistry AS RegisteredInPlatonSystemRegistry,
		|	CatalogData.Manufacturer_ AS Manufacturer_,
		|	CatalogData.Class AS Class,
		|	CatalogData.Subclass AS Subclass,
		|	CatalogData.CodeByRNCFA AS CodeByRNCFA,
		|	CatalogData.Model AS Model,
		|	CatalogData.PassportNumber AS PassportNumber,
		|	CatalogData.HouseholdObject AS HouseholdObject,
		|	CatalogData.OperatingBusinessUnit AS OperatingBusinessUnit,
		|	CatalogData.RMBusinessUnit AS RMBusinessUnit,
		|	CatalogData.SerialNumber AS SerialNumber,
		|	CatalogData.PayrollExpensesPostingMethod AS PayrollExpensesPostingMethod,
		|	CatalogData.Status AS Status,
		|	CatalogData.CodeByUFADR AS CodeByUFADR,
		|	CatalogData.ConsiderResidualLiabilityValue AS ConsiderResidualLiabilityValue
		|
		|INTO TTFAList
		|
		|FROM
		|	Catalog.Assets AS CatalogData
		|
		|WHERE
		|	CatalogData.Ref IN (&ObjectsArray)
		|	AND NOT CatalogData.IsFolder
		|	AND NOT CatalogData.DeletionMark
		|
		|INDEX BY
		|	Ref
		|";
		ListOfRequests.Add(QueryText);
		
		JoinText = "";
		
		If DescriptionOfSelectionRequest.RequiredTables.Property("FALocation") Then
			
			QueryText =
			"SELECT
			|	RegisterData.Organization AS Organization,
			|	RegisterData.FixedAsset AS FixedAsset,
			|	RegisterData.FixedAssetsLocation AS FixedAssetsLocation,
			|	RegisterData.Leaseholder AS Leaseholder
			|
			|INTO FALocation
			|
			|FROM
			|	InformationRegister.FALocation.SliceLast(
			|			&DateOfLastEdit,
			|			&Parameters_SliceOfLAST_CONDITIONS
			|				AND CorrectionDate = DATETIME(1,1,1)
			|				AND FixedAsset IN (
			|					SELECT 
			|						TTFAList.Ref 
			|					FROM 
			|						TTFAList AS TTFAList)) AS RegisterData
			|
			|INDEX BY
			|	FixedAsset,
			|	Organization
			|";
			ListOfRequests.Add(QueryText);
			
			JoinText = JoinText + "
			|		LEFT JOIN FALocation AS FALocation
			|		ON FALocation.FixedAsset = CatalogDataOverridable.Ref
			|"; // @query-part-1
			
		EndIf;
		
		If DescriptionOfSelectionRequest.RequiredTables.Property("InitialFixedAssetsInformation") Then
			
			QueryText =
			"SELECT
			|	RegisterData.Organization AS Organization,
			|	RegisterData.FixedAsset AS FixedAsset,
			|	RegisterData.CommissioningDateAC AS CommissioningDateAC,
			|	RegisterData.CommissioningDateTA AS CommissioningDateTA,
			|	RegisterData.CommissioningDateMA AS CommissioningDateMA,
			|	RegisterData.DepreciationMethodAccounting AS DepreciationMethodAccounting,
			|	RegisterData.DepreciationMethodTaxAccounting AS DepreciationMethodTaxAccounting
			|
			|INTO InitialFixedAssetsInformation
			|
			|FROM
			|	InformationRegister.InitialFixedAssetsInformation.SliceLast(
			|			&DateOfLastEdit,
			|			&Parameters_SliceOfLAST_CONDITIONS
			|				AND CorrectionDate = DATETIME(1,1,1)
			|				AND (Organization, FixedAsset) IN (
			|					SELECT 
			|						FALocation.Organization,  
			|						FALocation.FixedAsset  
			|					FROM 
			|						FALocation AS FALocation)) AS RegisterData
			|
			|INDEX BY
			|	FixedAsset,
			|	Organization
			|";
			ListOfRequests.Add(QueryText);

			JoinText = JoinText + "
			|		LEFT JOIN InitialFixedAssetsInformation AS InitialFixedAssetsInformation
			|		ON InitialFixedAssetsInformation.Organization = FALocation.Organization
			|			AND InitialFixedAssetsInformation.FixedAsset = FALocation.FixedAsset
			|"; // @query-part-1
			
		EndIf;
		
		If DescriptionOfSelectionRequest.RequiredTables.Property("FixedAssetsAccountingProcedureManagementAccounting") Then
			
			QueryText =
			"SELECT
			|	RegisterData.Organization AS Organization,
			|	RegisterData.FixedAsset AS FixedAsset,
			|	RegisterData.State AS State
			|
			|INTO FixedAssetsAccountingProcedureManagementAccounting
			|
			|FROM
			|	InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
			|			&DateOfLastEdit,
			|			&Parameters_SliceOfLAST_CONDITIONS
			|				AND CorrectionDate = DATETIME(1,1,1)
			|				AND (Organization, FixedAsset) IN (
			|					SELECT 
			|						FALocation.Organization,  
			|						FALocation.FixedAsset  
			|					FROM 
			|						FALocation AS FALocation)) AS RegisterData
			|
			|INDEX BY
			|	FixedAsset,
			|	Organization
			|";
			ListOfRequests.Add(QueryText);

			JoinText = JoinText + "
			|		LEFT JOIN FixedAssetsAccountingProcedureManagementAccounting AS FixedAssetsAccountingProcedureManagementAccounting
			|		ON FixedAssetsAccountingProcedureManagementAccounting.Organization = FALocation.Organization
			|			AND FixedAssetsAccountingProcedureManagementAccounting.FixedAsset = FALocation.FixedAsset
			|"; // @query-part-1
			
		EndIf;
		
		If DescriptionOfSelectionRequest.RequiredTables.Property("AccountingProcedureForOSBU") Then
			
			QueryText =
			"SELECT
			|	RegisterData.Organization AS Organization,
			|	RegisterData.FixedAsset AS FixedAsset,
			|	RegisterData.BUState AS BUState,
			|	RegisterData.StateTa AS StateTa,
			|	RegisterData.DepreciationGroup AS DepreciationGroup,
			|	RegisterData.RealEstate AS RealEstate
			|
			|INTO AccountingProcedureForOSBU
			|
			|FROM
			|	InformationRegister.AccountingProcedureForOSBU.SliceLast(
			|			&DateOfLastEdit,
			|			&Parameters_SliceOfLAST_CONDITIONS
			|				AND CorrectionDate = DATETIME(1,1,1)
			|				AND (Organization, FixedAsset) IN (
			|					SELECT 
			|						FALocation.Organization,  
			|						FALocation.FixedAsset  
			|					FROM 
			|						FALocation AS FALocation)) AS RegisterData
			|
			|INDEX BY
			|	FixedAsset,
			|	Organization
			|";
			ListOfRequests.Add(QueryText);

			JoinText = JoinText + "
			|		LEFT JOIN AccountingProcedureForOSBU AS AccountingProcedureForOSBU
			|		ON AccountingProcedureForOSBU.Organization = FALocation.Organization
			|			AND AccountingProcedureForOSBU.FixedAsset = FALocation.FixedAsset
			|"; // @query-part-1
			
		EndIf;
	
		If DescriptionOfSelectionRequest.RequiredTables.Property("FixedAssetDepreciationParametersManagementAccounting") Then
			
			QueryText =
			"SELECT
			|	RegisterData.Organization AS Organization,
			|	RegisterData.FixedAsset AS FixedAsset,
			|	RegisterData.UsefulLifeMonths AS UsefulLifeMonths,
			|	RegisterData.DepreciationMethod AS DepreciationMethod
			|
			|INTO FixedAssetDepreciationParametersManagementAccounting
			|
			|FROM
			|	InformationRegister.FixedAssetDepreciationParametersManagementAccounting.SliceLast(
			|			&DateOfLastEdit,
			|			&Parameters_SliceOfLAST_CONDITIONS
			|				AND CorrectionDate = DATETIME(1,1,1)
			|				AND (Organization, FixedAsset) IN (
			|					SELECT 
			|						FALocation.Organization,  
			|						FALocation.FixedAsset  
			|					FROM 
			|						FALocation AS FALocation)) AS RegisterData
			|
			|INDEX BY
			|	FixedAsset,
			|	Organization
			|";
			ListOfRequests.Add(QueryText);

			JoinText = JoinText + "
			|		LEFT JOIN FixedAssetDepreciationParametersManagementAccounting AS FixedAssetDepreciationParametersManagementAccounting
			|		ON FixedAssetDepreciationParametersManagementAccounting.Organization = FALocation.Organization
			|			AND FixedAssetDepreciationParametersManagementAccounting.FixedAsset = FALocation.FixedAsset
			|"; // @query-part-1
			
		EndIf;
		
		If DescriptionOfSelectionRequest.RequiredTables.Property("OSBUDepreciationParameters") Then
			
			QueryText =
			"SELECT
			|	RegisterData.Organization AS Organization,
			|	RegisterData.FixedAsset AS FixedAsset,
			|	RegisterData.UsefulLifeMonthsAC AS UsefulLifeMonthsAC,
			|	RegisterData.UsefulLifeMonthsTA AS UsefulLifeMonthsTA
			|
			|INTO OSBUDepreciationParameters
			|
			|FROM
			|	InformationRegister.OSBUDepreciationParameters.SliceLast(
			|			&DateOfLastEdit,
			|			&Parameters_SliceOfLAST_CONDITIONS
			|				AND CorrectionDate = DATETIME(1,1,1)
			|				AND (Organization, FixedAsset) IN (
			|					SELECT 
			|						FALocation.Organization,  
			|						FALocation.FixedAsset  
			|					FROM 
			|						FALocation AS FALocation)) AS RegisterData
			|
			|INDEX BY
			|	FixedAsset,
			|	Organization
			|";
			ListOfRequests.Add(QueryText);

			JoinText = JoinText + "
			|		LEFT JOIN OSBUDepreciationParameters AS OSBUDepreciationParameters
			|		ON OSBUDepreciationParameters.Organization = FALocation.Organization
			|			AND OSBUDepreciationParameters.FixedAsset = FALocation.FixedAsset
			|"; // @query-part-1
			
		EndIf;
		
		If DescriptionOfSelectionRequest.RequiredTables.Property("FixedAssetsAccountingProcedure") Then
			
			QueryText =
			"SELECT
			|	RegisterData.FixedAsset AS FixedAsset,
			|	RegisterData.FinancialAccountingGroup AS FinancialAccountingGroup,
			|	RegisterData.LineOfBusiness AS LineOfBusiness
			|
			|INTO FixedAssetsAccountingProcedure
			|
			|FROM
			|	InformationRegister.FixedAssetsAccountingProcedure.SliceLast(
			|			&DateOfLastEdit,
			|			&Parameters_SliceOfLAST_CONDITIONS
			|				AND CorrectionDate = DATETIME(1,1,1)
			|				AND FixedAsset IN (
			|					SELECT 
			|						TTFAList.Ref  
			|					FROM 
			|						TTFAList AS TTFAList)) AS RegisterData
			|
			|INDEX BY
			|	FixedAsset
			|";
			ListOfRequests.Add(QueryText);

			JoinText = JoinText + "
			|		LEFT JOIN FixedAssetsAccountingProcedure AS FixedAssetsAccountingProcedure
			|		ON FixedAssetsAccountingProcedure.FixedAsset = CatalogDataOverridable.Ref
			|"; // @query-part-1
			
		EndIf;
		
		If DescriptionOfSelectionRequest.RequiredTables.Property("LeasedAsset") Then
			
			QueryText =
			"SELECT
			|	RegisterData.FixedAsset AS FixedAsset,
			|	RegisterData.Partner AS Partner,
			|	RegisterData.Counterparty AS Counterparty,
			|	RegisterData.Contract AS Contract
			|
			|INTO LeasedAsset
			|
			|FROM
			|	InformationRegister.LeasedAsset.SliceLast(
			|			&DateOfLastEdit,
			|			FixedAsset IN (
			|					SELECT 
			|						TTFAList.Ref  
			|					FROM 
			|						TTFAList AS TTFAList)) AS RegisterData
			|
			|INDEX BY
			|	FixedAsset
			|";
			ListOfRequests.Add(QueryText);

			JoinText = JoinText + "
			|		LEFT JOIN LeasedAsset AS LeasedAsset
			|		ON LeasedAsset.FixedAsset = CatalogDataOverridable.Ref
			|"; // @query-part-1
			
		EndIf;
	
		QueryText =
		"SELECT ALLOWED TOP 10
		|	CatalogDataOverridable.Ref AS Ref,
		|	CatalogDataOverridable.Description AS Description,
		|	CatalogDataOverridable.AssetID AS AssetID
		|
		|FROM
		|	TTFAList AS CatalogDataOverridable
		|";
		
		If ValueIsFilled(JoinText) Then
			QueryText = QueryText + Chars.LF + JoinText;
		EndIf;
		
		ListOfRequests.Add(QueryText);
		
		QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
		
		TextSelections = "";

	Else
		
		QueryText =		
		"SELECT ALLOWED
		|	CatalogDataOverridable.Ref AS Ref
		|
		|FROM	
		|	Catalog.Assets AS CatalogDataOverridable
		|";
		
		TextSelections = 
		"WHERE
		|	CatalogDataOverridable.Ref IN (&ObjectsArray)
		|	AND NOT CatalogDataOverridable.IsFolder
		|	AND NOT CatalogDataOverridable.DeletionMark
		|";
		
	EndIf;

	If Not IsBlankString(DescriptionOfSelectionRequest.TextSelections) Then
		TextAnd = "AND"; // @query-part-1
		WhereText = "WHERE"; // @query-part-1
		TextSelections = TextSelections 
			+ ?(TextSelections <> "", Chars.LF + TextAnd, WhereText) + Chars.LF + DescriptionOfSelectionRequest.TextSelections; 
	EndIf;
	
	If Not IsBlankString(TextSelections) Then
		QueryText = QueryText + Chars.LF + TextSelections;
	EndIf;
	
	SliceParametersOfLast_Period = "";
	ParametersOfRecent_CorrectionDate = "TRUE";
	ParametersOfSliceOfLast_Conditions = "TRUE";
	SliceParameters_Registration = "TRUE";
	
	If ChoiceParameters.Property("DateOfLastEdit") Then
		SliceParametersOfLast_Period = "&DateOfLastEdit";
		ParametersOfRecent_CorrectionDate = "CorrectionDate = DATETIME(1,1,1)";
	EndIf; 
	
	If ChoiceParameters.Property("CurrentRegistrar") Then
		ParametersOfSliceOfLast_Conditions = "Recorder <> &CurrentRegistrar";
	EndIf; 

	If ChoiceParameters.Property("ThereAreParametersForCalculatingTransportTax")
			And ChoiceParameters.ThereAreParametersForCalculatingTransportTax
		Or ChoiceParameters.Property("ThereAreParametersForCalculatingLandTax")
			And ChoiceParameters.ThereAreParametersForCalculatingLandTax Then
		
		SliceParameters_Registration = ParametersOfSliceOfLast_Conditions;
		
		If ChoiceParameters.Filter.Property("Organization")
			And ValueIsFilled(ChoiceParameters.Filter.Organization) Then
			
			SliceParameters_Registration = 
				SliceParameters_Registration 
				+ ?(SliceParameters_Registration <> "", " And ", "")
				+ "Organization = &Organization";
				
		EndIf; 
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&PARAMETERS_AFTERLAST_Period", SliceParametersOfLast_Period);
	QueryText = StrReplace(QueryText, "&PARAMETERS_LAST_CorrectionDate", ParametersOfRecent_CorrectionDate);
	QueryText = StrReplace(QueryText, "&Parameters_SliceOfLAST_CONDITIONS", ParametersOfSliceOfLast_Conditions);
	QueryText = StrReplace(QueryText, "&PARAMETERS_LAST_REFERENCES", SliceParameters_Registration);

	Query = New Query(QueryText);
	Query.TempTablesManager = New TempTablesManager();
		Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.SetParameter("DateOfLastEdit", ?(ChoiceParameters.Property("DateOfLastEdit"), EndOfDay(ChoiceParameters.DateOfLastEdit), '00010101'));
	
	For Each ParameterDetails In DescriptionOfSelectionRequest.QueryOptions Do
		Query.SetParameter(ParameterDetails.Key, ParameterDetails.Value);
	EndDo;

	If ChoiceParameters.Property("CurrentRegistrar") Then
		Query.SetParameter("CurrentRegistrar", ChoiceParameters.CurrentRegistrar);
	EndIf; 
	
	If ChoiceParameters.Filter.Property("State") Then
		
		FilterValue = NonCurrentAssetsInternal.ValueToArray(ChoiceParameters.Filter.State);
		
		Query.SetParameter("State", FilterValue);
		Query.SetParameter("DoNotUseStateSelection", Not ValueIsFilled(FilterValue));
		
	Else			
		
		FilterValue = New Array;
		FilterValue.Add(Enums.FixedAssetsStates.EmptyRef());
		
		Query.SetParameter("State", FilterValue);
		Query.SetParameter("DoNotUseStateSelection", True);
		
	EndIf;

	AvailableObjects = Query.Execute().Unload().UnloadColumn("Ref");
	
	DeletedLinks = New Array;
	
	For Cnt = -ObjectsArray.UBound() To 0 Do
		If AvailableObjects.Find(ObjectsArray[-Cnt]) = Undefined Then
			DeletedLinks.Add(ObjectsArray[-Cnt]);
			ObjectsArray.Delete(-Cnt);
		EndIf; 
	EndDo; 

	Return DeletedLinks;
	
EndFunction

// Generates movements in the information register when updating information security.
// 
// Parameters:
// 	RegisterName	- String - register name.
// 	Parameters	- Structure	- parameters of the update handler.
//
// Returns:
//	Number - number of processed objects
Function GenerateRegisteredRecordsWhenUpdatingInformationSecurity(RegisterName, Parameters) Export
	
	ObjectsProcessed = 0;
	
	FullRegisterName = "InformationRegister." + RegisterName;
	RegisterMetadata = Metadata.InformationRegisters[RegisterName];
	
	If Not RegistrarsUpdated(RegisterName, Parameters) Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName);
		Return 0;
	EndIf;

	#Region FormationOfRegisteredRecords
	
	AdditionalProcessingDataSelectionParameters = InfobaseUpdate.AdditionalProcessingDataSelectionParameters();
	AdditionalProcessingDataSelectionParameters.SelectInBatches = False;

	TempTablesManager = New TempTablesManager;
	ProcessingParameters = InfobaseUpdate.CreateTemporaryTableOfRegisterRecordersToProcess(
							Parameters.Queue, 
							Undefined, 
							FullRegisterName, 
							TempTablesManager, 
							AdditionalProcessingDataSelectionParameters);

	CreateTemporaryTableWithDocumentDataForProcessing(
		RegisterMetadata, 
		ProcessingParameters.TempTableName, 
		TempTablesManager);

	// Documents need to be selected in chronological order, because when forming movements, a slice of the latter is used.
	QueryText = 
	"SELECT DISTINCT TOP 100
	|	TTToProcess.Recorder AS Recorder,
	|	ISNULL(TTDocumentDataForProcessing.Date, DATETIME(1,1,1)) AS Period
	|FROM
	|	TTToProcess AS TTToProcess
	|
	|		LEFT JOIN TTDocumentDataForProcessing AS TTDocumentDataForProcessing
	|		ON TTDocumentDataForProcessing.Ref = TTToProcess.Recorder
	|
	|WHERE
	|	VALUETYPE(TTToProcess.Recorder) <> TYPE(Document.RegisterAdjustment)
	|
	|ORDER BY
	|	ISNULL(TTDocumentDataForProcessing.Date, DATETIME(1,1,1))";

	QueryText = StrReplace(QueryText, "TTToProcess", ProcessingParameters.TempTableName);

	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;

	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	While Selection.Next() Do

		GetRegisteredRecordsAndRecordWhenUpdatingIB(
			RegisterName, 
			FullRegisterName, 
			Selection.Recorder, 
			RegisterMetadata, 
			Parameters);

		ObjectsProcessed = ObjectsProcessed + 1;
		
	EndDo;

	#EndRegion

	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName);
	
	Return ObjectsProcessed;
	
EndFunction

// Checks for updated register registrars.
// 
// Parameters:
// 	RegisterName	- String - register name.
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
// Returns:
// 	Boolean - False if the registrars are not updated.
//
Function RegistrarsUpdated(RegisterName, Parameters) Export
	
	FullRegisterName = "InformationRegister." + RegisterName;
	RegisterMetadata = Metadata.InformationRegisters[RegisterName];
	
	ReadableData = New Array;
	For Each MetadataOfDocument In Metadata.Documents Do
		If MetadataOfDocument = Metadata.Documents.RegisterAdjustment Then
			Continue;			
		EndIf;
		If MetadataOfDocument.RegisterRecords.Contains(RegisterMetadata) Then
			ReadableData.Add("Document." + MetadataOfDocument.Name);
		EndIf;		
	EndDo;
	
	If ReadableData.Count() <> 0
		And InfobaseUpdate.HasDataLockedByPreviousQueues(Parameters.Queue, ReadableData) Then
		Return False;
	EndIf;

	Return True;
	
EndFunction

// Creates a temporary table with object data.
// 
// Parameters:
//  RegisterMetadata - MetadataObjectInformationRegister - Register metadata.
//  NameOfTTTableToProcess - String - The name of the table is "VT for processing".
//  TempTablesManager - TempTablesManager - temporary table Manager
Procedure CreateTemporaryTableWithDocumentDataForProcessing(RegisterMetadata, NameOfTTTableToProcess, TempTablesManager) Export

	ListOfObjects = New Array;
	For Each MetadataOfDocument In Metadata.Documents Do
		If MetadataOfDocument <> Metadata.Documents.RegisterAdjustment
			And MetadataOfDocument.RegisterRecords.Contains(RegisterMetadata) Then
			ListOfObjects.Add(MetadataOfDocument.FullName());
		EndIf;
	EndDo;

	QueryTexts = New Array;
	For Each FullObjectName In ListOfObjects Do
		
		QueryText = 
		"SELECT
		|	Table.Ref AS Ref,
		|	Table.Date AS Date,
		|	Table.Organization AS Organization
		| 
		|INTO TTDocumentDataForProcessing
		|FROM
		|	&Table AS Table
		|WHERE
		|	Table.Ref IN (
		|		SELECT
		|			ReferencesToProcess.Recorder
		|		FROM
		|			TTToProcess AS ReferencesToProcess)";
	
		QueryText = StrReplace(QueryText, "&Table", FullObjectName);
		QueryText = StrReplace(QueryText, "TTToProcess", NameOfTTTableToProcess);
		
		If QueryTexts.Count() > 0 Then
			QueryText = StrReplace(QueryText, "INTO TTDocumentDataForProcessing", "");
		EndIf;
		
		QueryTexts.Add(QueryText);
		
	EndDo;
	
	QueryText = StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryText = QueryText + "
	|
	|INDEX BY
	|	Ref";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	
	Query.Execute();
	
EndProcedure

// Gets a table of document movements and writes it to the register.
// 
// Parameters:
// 	RegisterName - String - 
// 	FullRegisterName - String - 
// 	Recorder - Arbitrary - 
// 	RegisterMetadata - MetadataObjectInformationRegister - 
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
Procedure GetRegisteredRecordsAndRecordWhenUpdatingIB(RegisterName, FullRegisterName, Recorder, RegisterMetadata, Parameters) Export

	BeginTransaction();

	Try

		Block = New DataLock;
		LockItem = Block.Add(Common.TableNameByRef(Recorder));
		LockItem.SetValue("Ref", Recorder);

		LockItem = Block.Add(FullRegisterName + ".RecordSet");
		LockItem.SetValue("Recorder", Recorder);

		Block.Lock();

		// We get a table of movements.
		RegisterTable = Undefined;

		If Common.ObjectAttributeValue(Recorder, "Posted") = True Then
			ManagerOfDocument = Common.ObjectManagerByRef(Recorder);
			TablesForRegisteredRecords = ManagerOfDocument.DocumentDataForPosting(Recorder, RegisterName);
			TablesForRegisteredRecords.Property("Table" + RegisterName, RegisterTable);
		EndIf;

		// Recording a table of movements.
		If RegisterTable <> Undefined Then

			RegisterManager = Common.ObjectManagerByFullName(FullRegisterName);
			RecordSet = RegisterManager.CreateRecordSet(); // AccumulationRegisterRecordSet, InformationRegisterRecordSet - 
			RecordSet.Filter.Recorder.Set(Recorder);
			RecordSet.Load(RegisterTable);
			InfobaseUpdate.WriteData(RecordSet);

		Else

			AdditionalProcessingMarkParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
			AdditionalProcessingMarkParameters.IsRegisterRecords = True;
			AdditionalProcessingMarkParameters.FullRegisterName = FullRegisterName;
			
			InfobaseUpdate.MarkProcessingCompletion(
				Recorder, 
				AdditionalProcessingMarkParameters, 
				Parameters.Queue);

		EndIf;

		CommitTransaction();

	Except

		RollbackTransaction();

		MessageText = StrTemplate(NStr("vi = 'Không thể xử lý các bản ghi của biểu ghi ""%1"": %2 do nguyên nhân: %3';
										|ru = 'Не удалось обработать записи регистра ""%1"": %2 по причине: %3';
										|en = 'Cannot process records in register ""%1"": %2. Reason: %3'; fa = 'Cannot process records in register ""%1"": %2. Reason: %3';
										|it = 'Non è stato possibile elaborare le scritture del registro ""%1"": %2 a causa: %3';
										|pl = 'Nie udało się przetworzyć wpisu rejestru ""%1"": %2 z powodu: %3';
										|tr = 'Kayıt girişleri işlenemedi ''''%1""%2: çünkü: %3'"),
									?(ValueIsFilled(RegisterMetadata.Synonym), RegisterMetadata.Synonym, RegisterMetadata.Name),
									String(Recorder),
									DetailErrorDescription(ErrorInfo()));
									
		WriteLogEvent(
			InfobaseUpdate.EventLogEvent(), 
			EventLogLevel.Warning, 
			Recorder.Metadata(), 
			Recorder, 
			MessageText);

	EndTry;
	
EndProcedure

// Adds roles to the profile that allow you to work in the VNA subsystem with change rights.
// 
// Parameters:
// 	ProfileDetails - See AccessManagement.NewAccessGroupProfileDescription
Procedure AddRolesToAccessSubsystemInResponseToChange(ProfileDetails) Export
	
	// Reference books.
	ProfileDetails.Roles.Add("AddEditIntangibleAssetGroups");
	ProfileDetails.Roles.Add("AddEditFixedIntangibleAssetsAccountingGroups");
	ProfileDetails.Roles.Add("AddEditIntangibleAssets");
	ProfileDetails.Roles.Add("AddEditConstructionObjects");
	ProfileDetails.Roles.Add("AddEditAssets");
	ProfileDetails.Roles.Add("AddEditAttachedFilesOfFixedAssetDocuments");
	ProfileDetails.Roles.Add("AddEditFixedAssetsDisposalReasons");
	ProfileDetails.Roles.Add("AddEditFixedAssetsEvents");
	ProfileDetails.Roles.Add("AddEditExpenseRecordMethods");
	ProfileDetails.Roles.Add("AddEditRDStagesTopics");

	// Documents.
	ProfileDetails.Roles.Add("AddEditIntangibleAssetsAmortization");
	ProfileDetails.Roles.Add("AddEditFixedAssetDepreciation");
	ProfileDetails.Roles.Add("AddEditOBEntryFixedAssetCostAndDepreciation");
	ProfileDetails.Roles.Add("AddEditOBEntrySubAssetsAndComponentsOfDepreciation");
	ProfileDetails.Roles.Add("AddEditIncludeCostVariancesInFixedAssetCost");
	ProfileDetails.Roles.Add("AddEditFixedAssetsReturnsFromLeaseholder");
	ProfileDetails.Roles.Add("AddEditLeasedAssetsReturns");
	ProfileDetails.Roles.Add("AddEditIntangibleAssetsOperatingTime");
	ProfileDetails.Roles.Add("AddEditAdjustmentsOfIntangibleAssetsFinancialDetails");
	ProfileDetails.Roles.Add("AddEditAdjustFixedAssetFinancialDetails");
	ProfileDetails.Roles.Add("AddEditIntangibleAssetsPhysicalCount");
	ProfileDetails.Roles.Add("AddAndEditFixedAssetsPhysicalInventory");
	ProfileDetails.Roles.Add("AddEditIntangibleAssetsCostAndAmortizationAdjustmentEntries");
	ProfileDetails.Roles.Add("AddEditFixedAssetsCostAndDepreciationAdjustmentEntries");
	ProfileDetails.Roles.Add("AddEditFixedAssetsCostAdditions");
	ProfileDetails.Roles.Add("AddEditAssetActivityRecords");
	ProfileDetails.Roles.Add("AddEditFixedAssetsMerges");
	ProfileDetails.Roles.Add("AddEditTransfersOfFixedAssetsToLeaseholder");
	ProfileDetails.Roles.Add("AddEditIntangibleAssetTransfers");
	ProfileDetails.Roles.Add("AddEditFixedAssetsTransfers");
	ProfileDetails.Roles.Add("AddEditIntangibleAssetRevaluation");
	ProfileDetails.Roles.Add("AddEditFixedAssetsRevaluation");
	ProfileDetails.Roles.Add("AddEditPreparingForIntangibleAssetSale");
	ProfileDetails.Roles.Add("AddEditPreparingForFixedAssetSale");
	ProfileDetails.Roles.Add("AddEditLeasedAssetsReceipts");
	ProfileDetails.Roles.Add("AddEditRDExpenseRecognition");
	ProfileDetails.Roles.Add("AddEditIntangibleAssetsInitialRecognition");
	ProfileDetails.Roles.Add("AddEditFixedAssetsRecognitions");
	ProfileDetails.Roles.Add("AddEditFixedAssetsSplit");
	ProfileDetails.Roles.Add("AddEditIntangibleAssetsDisposal");
	ProfileDetails.Roles.Add("AddEditFixedAssetsDisposal");
	ProfileDetails.Roles.Add("AddEditIntangibleAssetImprovement");
	
	// Registers.
	ProfileDetails.Roles.Add("ReadIntangibleAssetsAmortization");
	ProfileDetails.Roles.Add("ReadFixedAssetDepreciation");
	ProfileDetails.Roles.Add("ReadInformationOnIntangibleAssets");
	ProfileDetails.Roles.Add("ReadInformationOnFixedAssets");
	ProfileDetails.Roles.Add("ReadIntangibleAssetsCost");
	ProfileDetails.Roles.Add("ReadFixedAssetsCost");
	
	// Processing.
	ProfileDetails.Roles.Add("UseIntangibleAssetsDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("UseFixedAssetsDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("UseCorrectErrorsInFixedAssetAccountingDataProcessor");
	ProfileDetails.Roles.Add("UseRecognizeAndIncludeExpensesInFixedAssetCostDataProcessor");
	
	// Reports.
	ProfileDetails.Roles.Add("FAAccountantSReportsAndDataProcessors");
	ProfileDetails.Roles.Add("ReportsOfFixedAssetSection");
	
	// Visible subsystems of CI
	ProfileDetails.Roles.Add("FixedAssetsSubsystem");
	ProfileDetails.Roles.Add("SectionFixedAssets");
	
	// Depreciation of HPA
	ProfileDetails.Roles.Add("ReadFAImpairmentData");
	ProfileDetails.Roles.Add("AddEditFixedAssetsImpairmentData");
	
	NonCurrentAssetsLocalization.AddRolesToAccessSubsystemInResponseToChange(ProfileDetails);
	
EndProcedure

// Adds roles to the profile that allow you to work in the VNA subsystem with read rights.
// 
// Parameters:
// 	ProfileDetails - See AccessManagement.NewAccessGroupProfileDescription
Procedure AddRolesForReadAccessToVNASubsystem(ProfileDetails) Export
	
	// Reference books.
	ProfileDetails.Roles.Add("ReadIntangibleAssetGroups");
	ProfileDetails.Roles.Add("ReadFixedIntangibleAssetsAccountingGroups");
	ProfileDetails.Roles.Add("ReadIntangibleAssets");
	ProfileDetails.Roles.Add("ReadConstructionObjects");
	ProfileDetails.Roles.Add("ReadAssets");
	ProfileDetails.Roles.Add("ReadAttachedFilesOfFixedAssetDocuments");
	ProfileDetails.Roles.Add("ReadFixedAssetsDisposalReasons");
	ProfileDetails.Roles.Add("ReadFixedAssetsEvents");
	ProfileDetails.Roles.Add("ReadExpenseRecordMethods");
	ProfileDetails.Roles.Add("ReadResearchAndDevelopmentStagesTopics");

	// Documents.
	ProfileDetails.Roles.Add("ReadIntangibleAssetsAmortization");
	ProfileDetails.Roles.Add("ReadFixedAssetDepreciation");
	ProfileDetails.Roles.Add("ReadOBEntryFixedAssetCostAndDepreciation");
	ProfileDetails.Roles.Add("ReadOBEntrySubAssetsAndComponentsOfDepreciation");
	ProfileDetails.Roles.Add("ReadIncludeCostVariancesInFixedAssetCost");
	ProfileDetails.Roles.Add("ReadFixedAssetReturnsFromLeaseholder");
	ProfileDetails.Roles.Add("ReadLeasedAssetsReturns");
	ProfileDetails.Roles.Add("ReadIntangibleAssetsOperatingTime");
	ProfileDetails.Roles.Add("ReadAdjustmentsOfIntangibleAssetsFinancialDetails");
	ProfileDetails.Roles.Add("ReadAdjustFixedAssetFinancialDetails");
	ProfileDetails.Roles.Add("ReadIAStocktaking");
	ProfileDetails.Roles.Add("ReadFixedAssetsPhysicalInventory");
	ProfileDetails.Roles.Add("ReadIntangibleAssetsCostAndAmortizationAdjustmentEntries");
	ProfileDetails.Roles.Add("ReadAdjustFixedAssetCostAndDepreciation");
	ProfileDetails.Roles.Add("ReadFixedAssetsCostAdditions");
	ProfileDetails.Roles.Add("ReadAssetActivityRecords");
	ProfileDetails.Roles.Add("ReadFixedAssetsMerges");
	ProfileDetails.Roles.Add("ReadTransfersOfFixedAssetsToLeaseholder");
	ProfileDetails.Roles.Add("ReadIntangibleAssetTransfers");
	ProfileDetails.Roles.Add("ReadFixedAssetsTransfer");
	ProfileDetails.Roles.Add("ReadIntangibleAssetRevaluation");
	ProfileDetails.Roles.Add("ReadFixedAssetRevaluation");
	ProfileDetails.Roles.Add("ReadPreparingForIntangibleAssetSale");
	ProfileDetails.Roles.Add("ReadPreparingForFixedAssetSale");
	ProfileDetails.Roles.Add("ReadLeasedAssetsReceipts");
	ProfileDetails.Roles.Add("ReadRDExpenseRecognition");
	ProfileDetails.Roles.Add("ReadIntangibleAssetsInitialRecognition");
	ProfileDetails.Roles.Add("ReadFixedAssetsInitialRecognition");
	ProfileDetails.Roles.Add("ReadFixedAssetsSplit");
	ProfileDetails.Roles.Add("ReadIntangibleAssetsDisposal");
	ProfileDetails.Roles.Add("ReadFixedAssetsDisposal");
	ProfileDetails.Roles.Add("ReadIntangibleAssetImprovements");
	
	// Registers.
	ProfileDetails.Roles.Add("ReadIntangibleAssetsAmortization");
	ProfileDetails.Roles.Add("ReadFixedAssetDepreciation");
	ProfileDetails.Roles.Add("ReadInformationOnIntangibleAssets");
	ProfileDetails.Roles.Add("ReadInformationOnFixedAssets");
	ProfileDetails.Roles.Add("ReadIntangibleAssetsCost");
	ProfileDetails.Roles.Add("ReadFixedAssetsCost");
	
	// Processing.
	ProfileDetails.Roles.Add("UseLeaseDocumentsJournalDataProcessor");
	ProfileDetails.Roles.Add("UseIntangibleAssetsDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("UseFixedAssetsDocumentJournalDataProcessor");
	
	// Reports.
	ProfileDetails.Roles.Add("FAAccountantSReportsAndDataProcessors");
	ProfileDetails.Roles.Add("ReportsOfFixedAssetSection");
	
	// Visible subsystems of CI
	ProfileDetails.Roles.Add("FixedAssetsSubsystem");
	ProfileDetails.Roles.Add("SectionFixedAssets");
	
	NonCurrentAssetsLocalization.AddRolesForReadAccessToVNASubsystem(ProfileDetails);
	
EndProcedure

// Generates the Query Text that receives a "slice of the last" register.
// 
// Parameters:
//  RegisterName - String - Register name
//  NameOfSliceTable - String - Name Of The Slice Table.
//  NameOfMainTable - String - The name of the main table that should contain the Reference, Period, and register measurement fields
//  QueryTexts - ValueList of String - Request texts
//  ConformityOfMeasurements - Structure - Correspondence of measurements of the main table and register
//	ConsiderCorrections - Boolean - True if you need to take into account corrections by the previous date
Procedure QueryTextSliceOfLastRegisters(RegisterName, NameOfSliceTable, NameOfMainTable, QueryTexts, ConformityOfMeasurements = Undefined, ConsiderCorrections = False) Export

	If DocumentsPosting.ThereIsQueryTable(NameOfSliceTable, QueryTexts) Then
		Return;
	EndIf;
	
	If ConformityOfMeasurements = Undefined Then
		ConformityOfMeasurements = New Structure;
	EndIf;
	
	RegisterMetadata = Metadata.InformationRegisters[RegisterName];
	
	RegisterParameters = New Structure;
	RegisterParameters.Insert("ItIsIndependentRegister", RegisterMetadata.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent);
	RegisterParameters.Insert("SelectingFields", "");
	RegisterParameters.Insert("SamplingOfMeasurements", "");
	RegisterParameters.Insert("GroupingDimensions", "");
	RegisterParameters.Insert("MeasurementsIndex", "");
	RegisterParameters.Insert("ConditionForJoiningMainTable", "");
	RegisterParameters.Insert("ConditionForJoiningRegisterTables", "");
	
	SelectingFields = New Array;
	SamplingOfMeasurements = New Array;
	GroupingDimensions = New Array;
	MeasurementsIndex = New Array;
	ConditionForJoiningMainTable = New Array;
	ConditionForJoiningRegisterTables = New Array;
	
	PartOfRequestAs = " AS "; // @query-part
	PartOfRequestAnd = " AND "; // @query-part
	
	ExcludeMeasurementsFromConnection = New Array;
	For Each KeyAndValue In ConformityOfMeasurements Do
		If KeyAndValue.Value = Undefined Then
			ExcludeMeasurementsFromConnection.Add(KeyAndValue.Key);
		EndIf;
	EndDo;
	
	For Each MetadataDimensions In RegisterMetadata.Dimensions Do
		
		PathToField = "RegisterTable." + MetadataDimensions.Name;
		SelectingFields.Add(PathToField + PartOfRequestAs + MetadataDimensions.Name);
		
		If ExcludeMeasurementsFromConnection.Find(MetadataDimensions.Name) = Undefined Then
			
			PathToField = "RegisterTable." + MetadataDimensions.Name;
			SamplingOfMeasurements.Add(PathToField + PartOfRequestAs + MetadataDimensions.Name);
			
			PathToField = "RegisterTable." + MetadataDimensions.Name;
			GroupingDimensions.Add(PathToField);
		
			DimensionName = MetadataDimensions.Name;
			If ConformityOfMeasurements.Property(MetadataDimensions.Name, DimensionName) Then
				PathToField = "RegisterTable." + MetadataDimensions.Name + " = " + "MainTable." + DimensionName;
			Else
				PathToField = "RegisterTable." + MetadataDimensions.Name + " = " + "MainTable." + MetadataDimensions.Name;
			EndIf;
			ConditionForJoiningMainTable.Add(PathToField);
			
			PathToField = "RegisterTable." + MetadataDimensions.Name + " = " + "MainTable." + MetadataDimensions.Name;
			ConditionForJoiningRegisterTables.Add(PathToField);

			MeasurementsIndex.Add(MetadataDimensions.Name);
			
		EndIf;

	EndDo;
	
	For Each MetadataDimensions In RegisterMetadata.Resources Do
		
		PathToField = "RegisterTable." + MetadataDimensions.Name;
		SelectingFields.Add(PathToField + PartOfRequestAs + MetadataDimensions.Name);
		
	EndDo; 
	
	If NonCurrentAssetsInternal.RegisterSupportsCorrection(RegisterName) Then
		
		If ConsiderCorrections Then
			ConditionForJoiningMainTable.Add("RegisterTable.CorrectionDate <= MainTable.Period");
			ConditionForJoiningRegisterTables.Add("RegisterTable.CorrectionDate <= MainTable.Period");
		Else
			ConditionForJoiningMainTable.Add("RegisterTable.CorrectionDate = DATETIME(1,1,1)");
			ConditionForJoiningRegisterTables.Add("RegisterTable.CorrectionDate = DATETIME(1,1,1)");
		EndIf;
		
	EndIf;
	
	If Not RegisterParameters.ItIsIndependentRegister Then
		ConditionForJoiningMainTable.Add("RegisterTable.Active");
		ConditionForJoiningRegisterTables.Add("RegisterTable.Active");
	EndIf;
	
	If Not RegisterParameters.ItIsIndependentRegister Then
		ConditionForJoiningMainTable.Add("RegisterTable.Recorder <> MainTable.Ref");
	EndIf;
	
	FieldSeparator = ",
	|	";
	RegisterParameters.SelectingFields = StrConcat(SelectingFields, FieldSeparator);
	RegisterParameters.SamplingOfMeasurements = StrConcat(SamplingOfMeasurements, FieldSeparator);
	RegisterParameters.GroupingDimensions = StrConcat(GroupingDimensions, FieldSeparator);
	RegisterParameters.MeasurementsIndex = StrConcat(MeasurementsIndex, FieldSeparator);
	
	FieldSeparator = "
	|" + PartOfRequestAnd;
	RegisterParameters.ConditionForJoiningMainTable = StrConcat(ConditionForJoiningMainTable, FieldSeparator);
	RegisterParameters.ConditionForJoiningRegisterTables = StrConcat(ConditionForJoiningRegisterTables, FieldSeparator);
	
	QueryText = 
	"SELECT
	|	MainTable.Ref AS Ref,
	|	MainTable.Period AS Period,
	|	&SamplingOfMeasurements,
	|	MAX(RegisterTable.Period) AS RegistrationPeriod_
	|
	|INTO VT_RegisterName_Period
	|
	|FROM
	|	TTListOfObjects AS MainTable
	|
	|		INNER JOIN InformationRegister.InitialFixedAssetsInformation AS RegisterTable
	|		ON (RegisterTable.Period <= MainTable.DocumentDate)
	|			AND &ConditionForJoiningMainTable
	|
	|GROUP BY
	|	MainTable.Ref,
	|	MainTable.Period,
	|	&GroupingDimensions
	|
	|INDEX BY
	|	RegistrationPeriod_,
	|	&MeasurementsIndex
	|";
	
	If ConformityOfMeasurements.Property("Period") Then
		QueryText = StrReplace(QueryText, "MainTable.DocumentDate", "MainTable" + "." + ConformityOfMeasurements.Period);
	Else
		QueryText = StrReplace(QueryText, "MainTable.DocumentDate", "MainTable.Period");
	EndIf;
	
	QueryText = StrReplace(QueryText, "TTListOfObjects", NameOfMainTable);
	QueryText = ReplaceQueryText(QueryText, RegisterName, "", RegisterParameters);

	QueryTexts.Add(QueryText, NameOfSliceTable, False);

	If RegisterParameters.ItIsIndependentRegister Then
		
		QueryText =
		"SELECT
		|	MainTable.Ref AS Ref,
		|	RegisterTable.Period AS Period,
		|	&SelectingFields
		|
		|INTO VT_RegisterSlice
		|
		|FROM
		|	VT_RegisterName_Period AS MainTable
		|
		|		INNER JOIN InformationRegister.InitialFixedAssetsInformation AS RegisterTable
		|		ON RegisterTable.Period = MainTable.RegistrationPeriod_
		|			AND &ConditionForJoiningRegisterTables
		|
		|INDEX BY
		|	Ref,
		|	&MeasurementsIndex
		|";
		QueryText = ReplaceQueryText(QueryText, RegisterName, NameOfSliceTable, RegisterParameters);
		QueryTexts.Add(QueryText, NameOfSliceTable, False);
		
	Else
		
		QueryText =
		"SELECT
		|	MainTable.Ref AS Ref,
		|	MainTable.Period AS Period,
		|	RegisterTable.Period AS RegistrationPeriod_,
		|	&SamplingOfMeasurements,
		|	MAX(RegisterTable.Recorder) AS RecorderOfRegisterTable
		|
		|INTO VT_RegistrarName_Registrar
		|
		|FROM
		|	VT_RegisterName_Period AS MainTable
		|
		|		INNER JOIN InformationRegister.InitialFixedAssetsInformation AS RegisterTable
		|		ON RegisterTable.Period = MainTable.RegistrationPeriod_
		|			AND RegisterTable.Recorder <> MainTable.Ref
		|			AND &ConditionForJoiningRegisterTables
		|
		|GROUP BY
		|	MainTable.Ref,
		|	MainTable.Period,
		|	RegisterTable.Period,
		|	&GroupingDimensions
		|
		|INDEX BY
		|	RecorderOfRegisterTable,
		|	RegistrationPeriod_,
		|	&MeasurementsIndex
		|";
		QueryText = ReplaceQueryText(QueryText, RegisterName, NameOfSliceTable, RegisterParameters);
		QueryTexts.Add(QueryText, "", False);
	
		QueryText =
		"SELECT
		|	MainTable.Ref AS Ref,
		|	RegisterTable.Period AS Period,
		|	&SelectingFields
		|
		|INTO VT_RegisterSlice
		|
		|FROM
		|	VT_RegistrarName_Registrar AS MainTable
		|
		|		INNER JOIN InformationRegister.InitialFixedAssetsInformation AS RegisterTable
		|		ON RegisterTable.Period = MainTable.RegistrationPeriod_
		|			AND RegisterTable.Recorder = MainTable.RecorderOfRegisterTable
		|			AND &ConditionForJoiningRegisterTables
		|
		|INDEX BY
		|	Ref,
		|	&MeasurementsIndex
		|";
		QueryText = ReplaceQueryText(QueryText, RegisterName, NameOfSliceTable, RegisterParameters);
		QueryTexts.Add(QueryText, NameOfSliceTable, False);
		
		QueryText =
		"DROP VT_RegistrarName_Registrar";
	
		QueryText = ReplaceQueryText(QueryText, RegisterName, NameOfSliceTable, RegisterParameters);
		QueryTexts.Add(QueryText, "", False);
		
	EndIf;
	
	QueryText =
	"DROP VT_RegisterName_Period";
	QueryText = ReplaceQueryText(QueryText, RegisterName, NameOfSliceTable, RegisterParameters);
	
	QueryTexts.Add(QueryText, "", False);
	
EndProcedure

// Generates the text of the request, which receives register entries, taking into account corrections.
// 
// Parameters:
// 	RegisterName - String - name of the information register.
// 	TempTableName - String - name of the temporary table.
// 	FieldNamePeriod - String - The name of the "Period" field.
// 	AdditionalFields - Structure - Allows you to add additional fields to the table (Key: field name, Value: Field expression).
// 	
// Returns:
// 	String - query text.
Function CaseRecordRequestTextWithCorrections(RegisterName, TempTableName = "", FieldNamePeriod = "", AdditionalFields = Undefined) Export
	
	If AdditionalFields = Undefined Then
		AdditionalFields = New Structure;
	EndIf;
	
	QueryText = 
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	&FieldTexts
	|
	|INTO TT_RegisterName
	|
	|FROM
	|	InformationRegister.FixedAssetsAccountingProcedure AS RegisterData
	|
	|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedure AS CorrectionRegisterData
	|		ON BEGINOFPERIOD(CorrectionRegisterData.Period, DAY) = BEGINOFPERIOD(RegisterData.Period, DAY)
	|			AND &OrganizationCONNECTION
	|			AND CorrectionRegisterData.FixedAsset = RegisterData.FixedAsset
	|			AND CorrectionRegisterData.Recorder <> RegisterData.Recorder
	|			AND (CorrectionRegisterData.CorrectionDate > RegisterData.CorrectionDate
	|				OR CorrectionRegisterData.CorrectionDate = RegisterData.CorrectionDate
	|						AND CorrectionRegisterData.Recorder > RegisterData.Recorder)
	|			AND (CorrectionRegisterData.CorrectionDate <= &DocumentDate
	|				OR &DocumentDate = DATETIME(1,1,1))
	|			AND CorrectionRegisterData.CorrectionDate <> DATETIME(1,1,1)
	|			AND CorrectionRegisterData.Active
	|
	|WHERE
	|	(RegisterData.Period >= &BeginOfPeriod
	|		OR &BeginOfPeriod = DATETIME(1,1,1))
	|
	|	AND (RegisterData.Period <= &EndOfPeriod
	|		OR &EndOfPeriod = DATETIME(1,1,1))
	|
	|	AND (RegisterData.CorrectionDate <= &DocumentDate
	|		OR &DocumentDate = DATETIME(1,1,1))
	|		
	|	AND &OrganizationWHERE
	|
	|	AND (RegisterData.FixedAsset IN (&ListOfFA)
	|		OR &WithoutFASelection)
	|
	|	AND RegisterData.Active
	|
	|	AND CorrectionRegisterData.Recorder IS NULL
	|";
	
	RegisterMetadata = Metadata.InformationRegisters[RegisterName];

	ThereIsACompany = False;

	FieldList = New Array;
	
	For Each MetadataDimensions In RegisterMetadata.Dimensions Do
		
		If AdditionalFields.Property(MetadataDimensions.Name) Then
			Continue;
		EndIf;
		
		FieldList.Add("RegisterData." + MetadataDimensions.Name + " AS " + MetadataDimensions.Name);
		If MetadataDimensions.Name = "Organization" Then
			ThereIsACompany = True;
		EndIf;
		 
	EndDo; 
	
	For Each ResourceMetadata In RegisterMetadata.Resources Do
		
		If AdditionalFields.Property(ResourceMetadata.Name) Then
			Continue;
		EndIf;

		PathToField = "RegisterData." + ResourceMetadata.Name;
		FieldList.Add(PathToField + " AS " + ResourceMetadata.Name);
		
	EndDo; 
	
	For Each AttributeMetadata In RegisterMetadata.Attributes Do
		
		If AdditionalFields.Property(AttributeMetadata.Name) Then
			Continue;
		EndIf;

		PathToField = "RegisterData." + AttributeMetadata.Name;
		FieldList.Add(PathToField + " AS " + AttributeMetadata.Name);
		
	EndDo;
	
	For Each KeyAndValue In AdditionalFields Do
		FieldList.Add(KeyAndValue.Value + " AS " + KeyAndValue.Key);
	EndDo;
	
	FieldSeparator = ",
	|	";
	FieldTexts = StrConcat(FieldList, FieldSeparator);
	
	If ThereIsACompany Then
		QueryText = StrReplace(QueryText, "&OrganizationCONNECTION", "CorrectionRegisterData.Organization = RegisterData.Organization");
		QueryText = StrReplace(QueryText, "&OrganizationWHERE", "RegisterData.Organization = &Organization");
	Else
		QueryText = StrReplace(QueryText, "&OrganizationCONNECTION", "TRUE");
		QueryText = StrReplace(QueryText, "&OrganizationWHERE", "TRUE");
	EndIf; 
	
	QueryText = StrReplace(QueryText, "InformationRegister.FixedAssetsAccountingProcedure", "InformationRegister." + RegisterName);
	QueryText = StrReplace(QueryText, "&FieldTexts", FieldTexts);
	QueryText = StrReplace(QueryText, "TT_RegisterName", ?(TempTableName <> "", TempTableName, NameOfRegisterOfRecordSubjectToCorrections(RegisterName)));
	
	QueryText = QueryText + "
	|INDEX BY
	|	FixedAsset" + ?(ThereIsACompany, ",Organization", "");
	
	If ValueIsFilled(FieldNamePeriod) Then
		QueryText = StrReplace(QueryText, "RegisterData.Period", "RegisterData." + FieldNamePeriod);
		QueryText = StrReplace(QueryText, "CorrectionRegisterData.Period", "CorrectionRegisterData." + FieldNamePeriod);
	EndIf;
	
	Return QueryText;
	
EndFunction

// Generates the text of the request, which receives a slice of the last case, taking into account corrections.
// 
// Parameters:
// 	RegisterName - String - name of the information register.
// 	TempTableName - String - name of the temporary table.
// 	AdditionalFields - Structure - Allows you to add additional fields to the table (Key: field name, Value: Field expression).
// 	QueryConditions - String - Request conditions.
// 	
// Returns:
// 	String - query text.
Function RequestTextCaseSensitiveWithCorrections(RegisterName, TempTableName = "", AdditionalFields = Undefined, QueryConditions = "") Export

	If AdditionalFields = Undefined Then
		AdditionalFields = New Structure;
	EndIf;

	QueryText = 
	"SELECT
	|	MAX(RegisterData.Period) AS Period,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.FixedAsset AS FixedAsset
	|
	|INTO TT_RegisterName_SectionPeriod
	| 
	|FROM
	|	InformationRegister.FixedAssetsAccountingProcedure AS RegisterData
	|
	|WHERE
	|	RegisterData.Period <= &Date
	|	AND RegisterData.CorrectionDate <= &DocumentDate
	|	AND RegisterData.Organization = &Organization
	|	AND (RegisterData.FixedAsset IN (&ListOfFA)
	|			OR &WithoutFASelection)
	|
	|	AND RegisterData.Active
	|
	|GROUP BY
	|	RegisterData.Organization,
	|	RegisterData.FixedAsset
	|
	|INDEX BY Period, FixedAsset, Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(ISNULL(RegistrationData_.CorrectionDate, DATETIME(1,1,1))) AS CorrectionDate,
	|	RegisterData_SlicePeriod.Period AS Period,
	|	RegisterData_SlicePeriod.Organization AS Organization,
	|	RegisterData_SlicePeriod.FixedAsset AS FixedAsset
	|
	|INTO TT_RegisterName_SliceCorrectionPeriod
	|
	|FROM
	|	TT_RegisterName_SectionPeriod AS RegisterData_SlicePeriod
	|
	|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedure AS RegistrationData_
	|		ON BEGINOFPERIOD(RegistrationData_.Period, DAY) = BEGINOFPERIOD(RegisterData_SlicePeriod.Period, DAY)
	|			AND RegistrationData_.Organization = RegisterData_SlicePeriod.Organization
	|			AND RegistrationData_.FixedAsset = RegisterData_SlicePeriod.FixedAsset
	|			AND RegistrationData_.CorrectionDate <= &DocumentDate
	|			AND RegistrationData_.CorrectionDate <> DATETIME(1,1,1)
	|			AND RegistrationData_.Active
	|
	|GROUP BY
	|	RegisterData_SlicePeriod.Period,
	|	RegisterData_SlicePeriod.Organization,
	|	RegisterData_SlicePeriod.FixedAsset
	|
	|INDEX BY Period, FixedAsset, Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_RegisterName_SectionPeriod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(RegisterData.Recorder) AS Recorder,
	|	RegisterData_SliceCorrectionPeriod.Period AS Period,
	|	RegisterData_SliceCorrectionPeriod.Organization AS Organization,
	|	RegisterData_SliceCorrectionPeriod.FixedAsset AS FixedAsset
	|
	|INTO TT_RegisterName_LoggerSlice
	|
	|FROM
	|	TT_RegisterName_SliceCorrectionPeriod AS RegisterData_SliceCorrectionPeriod
	|
	|		INNER JOIN InformationRegister.FixedAssetsAccountingProcedure AS RegisterData
	|		ON RegisterData.Organization = RegisterData_SliceCorrectionPeriod.Organization
	|			AND RegisterData.FixedAsset = RegisterData_SliceCorrectionPeriod.FixedAsset
	|			AND BEGINOFPERIOD(RegisterData.Period, DAY) = BEGINOFPERIOD(RegisterData_SliceCorrectionPeriod.Period, DAY)
	|			AND RegisterData.CorrectionDate = RegisterData_SliceCorrectionPeriod.CorrectionDate
	|			AND RegisterData.Active
	|
	|GROUP BY
	|	RegisterData_SliceCorrectionPeriod.Period,
	|	RegisterData_SliceCorrectionPeriod.Organization,
	|	RegisterData_SliceCorrectionPeriod.FixedAsset
	|
	|
	|INDEX BY Recorder, Period, FixedAsset, Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_RegisterName_SliceCorrectionPeriod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	&FieldTexts
	|
	|INTO TT_RegisterName
	|
	|FROM
	|	TT_RegisterName_LoggerSlice AS RegisterData_SliceLogger
	|
	|	INNER JOIN InformationRegister.FixedAssetsAccountingProcedure AS RegisterData
	|	ON RegisterData.Recorder = RegisterData_SliceLogger.Recorder
	|		AND BEGINOFPERIOD(RegisterData.Period, DAY) = BEGINOFPERIOD(RegisterData_SliceLogger.Period, DAY)
	|		AND RegisterData.Organization = RegisterData_SliceLogger.Organization
	|		AND RegisterData.FixedAsset = RegisterData_SliceLogger.FixedAsset
	|		AND RegisterData.Active
	|
	|WHERE
	|	&RegisterData_TableConditions
	|
	|INDEX BY FixedAsset, Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_RegisterName_LoggerSlice
	|";
	
	RegisterMetadata = Metadata.InformationRegisters[RegisterName];

	ThereIsACompany = False;

	FieldList = New Array;
	
	For Each MetadataDimensions In RegisterMetadata.Dimensions Do
		
		If AdditionalFields.Property(MetadataDimensions.Name) Then
			Continue;
		EndIf;
		
		FieldList.Add("	RegisterData." + MetadataDimensions.Name + " AS " + MetadataDimensions.Name);
		If MetadataDimensions.Name = "Organization" Then
			ThereIsACompany = True;
		EndIf;
		 
	EndDo; 
	
	For Each ResourceMetadata In RegisterMetadata.Resources Do
		
		If AdditionalFields.Property(ResourceMetadata.Name) Then
			Continue;
		EndIf;
		
		PathToField = "	RegisterData." + ResourceMetadata.Name;
		FieldList.Add(PathToField + " AS " + ResourceMetadata.Name);
		
	EndDo; 
	
	For Each AttributeMetadata In RegisterMetadata.Attributes Do
		
		If AdditionalFields.Property(AttributeMetadata.Name) Then
			Continue;
		EndIf;
		
		PathToField = "	RegisterData." + AttributeMetadata.Name;
		FieldList.Add(PathToField + " AS " + AttributeMetadata.Name);
		
	EndDo;
	 
	For Each KeyAndValue In AdditionalFields Do
		FieldList.Add(KeyAndValue.Value + " AS " + KeyAndValue.Key);
	EndDo;

	FieldSeparator = ",
	|	";
	FieldTexts = StrConcat(FieldList, FieldSeparator);
	
	If Not ThereIsACompany Then
		
		QueryText = StrReplace(QueryText, "RegisterDataBeforeCorrection.Organization = RegisterData_SlicePeriod.Organization", "TRUE");
		QueryText = StrReplace(QueryText, "RegistrationData_.Organization = RegisterData_SlicePeriod.Organization", "TRUE");
		QueryText = StrReplace(QueryText, "RegisterData.Organization = &Organization", "TRUE");
		QueryText = StrReplace(QueryText, "RegisterData.Organization = RegisterData_SliceCorrectionPeriod.Organization", "TRUE");
		QueryText = StrReplace(QueryText, "RegisterData.Organization = RegisterData_SliceLogger.Organization", "TRUE");
		QueryText = StrReplace(QueryText, "RegisterData.Organization", "UNDEFINED");
		QueryText = StrReplace(QueryText, "RegisterData_SlicePeriod.Organization", "UNDEFINED");
		
		QueryText = StrReplace(
			QueryText, 
			"INDEX BY Period, FixedAsset, Organization", 
			"INDEX BY Period, FixedAsset");
			
		QueryText = StrReplace(
			QueryText, 
			"INDEX BY Recorder, Period, FixedAsset, Organization", 
			"INDEX BY Recorder, Period, FixedAsset");
			
		QueryText = StrReplace(
			QueryText, 
			"INDEX BY FixedAsset, Organization", 
			"INDEX BY FixedAsset");
			
	EndIf; 
	
	QueryText = StrReplace(QueryText, "InformationRegister.FixedAssetsAccountingProcedure", "InformationRegister." + RegisterName);
	QueryText = StrReplace(QueryText, "&FieldTexts", FieldTexts);
	QueryText = StrReplace(QueryText, "TT_RegisterName", ?(TempTableName <> "", TempTableName, NameOfRegisterIsSliceOfLatestOnesTakingIntoAccountCorrections(RegisterName)));
	
	If Not IsBlankString(QueryConditions) Then
		QueryText = StrReplace(QueryText, "&RegisterData_TableConditions", QueryConditions);
	Else
		QueryText = StrReplace(QueryText, "&RegisterData_TableConditions", "TRUE");
	EndIf;
	
	Return QueryText;
	
EndFunction

// Replaces the table name in the query.
// 
// Parameters:
//  TableName - String - 
//  RegisterName - String - list of register names
//  QueryText - String - Query text
// 
Procedure ReplaceNameOfRecordRegisterTableWithCorrections(TableName, RegisterName, QueryText) Export
	
	QueryText = StrReplace(QueryText, TableName, NameOfRegisterOfRecordSubjectToCorrections(RegisterName));
	
EndProcedure

// Replaces the table name in the query.
// 
// Parameters:
//  TableName - String - 
//  RegisterName - String - list of register names
//  QueryText - String - Query text
// 
Procedure ReplaceNameOfRegisterTableWithSliceOfLatestOnesTakingIntoAccountCorrections(TableName, RegisterName, QueryText) Export
	
	QueryText = StrReplace(QueryText, TableName, NameOfRegisterIsSliceOfLatestOnesTakingIntoAccountCorrections(RegisterName));
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Documents.IntangibleAssetsPhysicalCount.OnAddUpdateHandlers(Handlers);
	Documents.FixedAssetsPhysicalCount.OnAddUpdateHandlers(Handlers);
	Documents.IntangibleAssetsCostAndAmortizationAdjustment.OnAddUpdateHandlers(Handlers);
	Documents.FixedAssetCostAndDepreciationAdjustment.OnAddUpdateHandlers(Handlers);
	Documents.FixedAssetsCostAdditions2_4.OnAddUpdateHandlers(Handlers);
	Documents.AllocateVariancesToFixedAssetCost.OnAddUpdateHandlers(Handlers);
	Documents.IntangibleAssetsInitialRecognition2_4.OnAddUpdateHandlers(Handlers);
	Documents.FixedAssetsInitialRecognition2_4.OnAddUpdateHandlers(Handlers);
	Documents.RecognizeSubAssetsComponentsOfDepreciation.OnAddUpdateHandlers(Handlers);
	Documents.DisposeIntangibleAssets2_4.OnAddUpdateHandlers(Handlers);
	Documents.DisposeFixedAssets2_4.OnAddUpdateHandlers(Handlers);
	Documents.IntangibleAssetImprovement.OnAddUpdateHandlers(Handlers);

	InformationRegisters.IABookkeepingProcedureBookkeepingAndTaxAccounting.OnAddUpdateHandlers(Handlers);
	InformationRegisters.AccountingProcedureForOSBU.OnAddUpdateHandlers(Handlers);

	InformationRegisters.IntangibleAssetsDocuments.OnAddUpdateHandlers(Handlers);
	InformationRegisters.FixedAssetsDocuments.OnAddUpdateHandlers(Handlers);

EndProcedure

// Check the article in the order of accounting.
// 
// Parameters:
//  Object - DocumentObject - Document
//  NameOfArticleField - String - Name of the field containing the article
//  AccountingProcedure - EnumRef.FARepaymentProcedure - Accounting Procedure
//  AccountingKind - String - Type of accounting
//  Cancel - Boolean - True if the check is completed with errors
Procedure CheckArticleInOrderOfAccounting(Object, NameOfArticleField, AccountingProcedure, AccountingKind, Cancel) Export
	
	ExpenseItem = Object[NameOfArticleField];
	
	If Not ValueIsFilled(ExpenseItem)
		Or Not ValueIsFilled(AccountingProcedure) Then
		Return;
	EndIf;
	
	ArrayOfDistributionOptions = NonCurrentAssetsClientServer.AvailableCostSharingOptions(AccountingProcedure);
	
	If ArrayOfDistributionOptions.Count() = 0 Then
		Return;
	EndIf; 
	
	If AccountingKind = "ACC" Then
		AttributeName = "CostAllocationOptionLocal";
	ElsIf AccountingKind = "TA" Then
		AttributeName = "CostAllocationOptionTax";
	Else
		AttributeName = "CostAllocationOptionManag";
	EndIf;
	
	ArticleDetails_1 = Common.ObjectAttributesValues(ExpenseItem, "Description" + "," + AttributeName);
	
	If ArrayOfDistributionOptions.Find(ArticleDetails_1[AttributeName]) = Undefined Then
		
		MessageText = NStr("vi = 'Không hỗ trợ phản ánh chi phí theo dạng ""%1"" với trình tự hạch toán ""%2"".
							  |Cần thay đổi trình tự hạch toán hoặc chọn dạng khác.';
							  |ru = 'Не поддерживается отражение расходов по статье ""%1"" при порядке учета ""%2"".
							  |Необходимо изменить порядок учета или выбрать другую статью.';
							  |en = 'Cannot record expenses for the ""%1"" item with the ""%2"" accounting procedure.
							  |Change the accounting procedure or choose another item.'; fa = 'Cannot record expenses for the ""%1"" item with the ""%2"" accounting procedure.
							  |Change the accounting procedure or choose another item.';
							  |it = 'Не поддерживается отражение расходов по статье ""%1"" при порядке учета ""%2"".
							  |Необходимо изменить порядок учета или выбрать другую статью.';
							  |pl = 'Cannot record expenses for the ""%1"" item with the ""%2"" accounting procedure.
							  |Change the accounting procedure or choose another item.';
							  |tr = '""%2"" muhasebe ilkesi altında ""%1"" kalemi için gider kaydedilemiyor.
							  |Muhasebe ilkesini пэвукdeğiştirmek veya başka bir kalem seçmek gerekiyor.'");
		MessageText = StrTemplate(MessageText, ArticleDetails_1.Description, AccountingProcedure);
		Common.MessageToUser(MessageText, Object, NameOfArticleField,, Cancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

#Region Other

Function GenerateTextForCombiningDataToFormTask(TablesList, TablesData, ListOfAddFields = Undefined, ListOfTableFields = Undefined) Export

	TextOfAdditionalFields = "";
	If ListOfAddFields <> Undefined Then
		If TypeOf(ListOfAddFields) = Type("String") Then
			// So that the same order of fields is observed.
			For Each FieldName In StrSplit(ListOfAddFields, ",") Do
				TextOfAdditionalFields = TextOfAdditionalFields + "
				|	, ChangedData." + FieldName + " AS " + FieldName;
			EndDo;
		Else
			For Each KeyAndValue In ListOfAddFields Do
				TextOfAdditionalFields = TextOfAdditionalFields + "
				|	, ChangedData." + ?(ValueIsFilled(KeyAndValue.Value), KeyAndValue.Value, KeyAndValue.Key) + " AS " + KeyAndValue.Key;
			EndDo;
		EndIf;
	EndIf; 
	
	If ListOfTableFields = Undefined Then
		ListOfTableFields = New Structure;
	EndIf;
	
	RowsArray = New Array;
	For Each TableName In TablesList Do
		
		TempTableName = TableName + "Update";
		
		If TypeOf(TablesData) = Type("TempTablesManager") Then
			ThereAreRecords = TablesData.Tables.Find(TempTableName) <> Undefined;
		Else
			ThereAreRecords = CommonClientServer.StructureProperty(TablesData, TempTableName, False);
		EndIf;
		
		If Not ThereAreRecords Then
			Continue;
		EndIf;
		
		TextOfTableFields = "";
		For Each KeyAndValue In ListOfTableFields Do
			If KeyAndValue.Value.Find(TableName) <> Undefined Then
				TextOfTableFields = TextOfTableFields + "
				|	, ChangedData." + KeyAndValue.Key + " AS " + KeyAndValue.Key;
			Else
				TextOfTableFields = TextOfTableFields + "
				|	, UNDEFINED AS " + KeyAndValue.Key;
			EndIf; 
		EndDo; 
		
		QueryText =
		"SELECT
		|	ChangedData.Period AS Period,
		|	ChangedData.Organization AS Organization,
		|	ChangedData.Document AS Document,
		|	&TableName AS TableName
		|	,&TextOfAdditionalFields
		|	,&TextOfTableFields
		|FROM
		|	&TempTableName AS ChangedData";
		
		QueryText = StrReplace(QueryText, "&TableName", """" + Upper(TableName) + """");
		QueryText = StrReplace(QueryText, ",&TextOfAdditionalFields", TextOfAdditionalFields);
		QueryText = StrReplace(QueryText, ",&TextOfTableFields", TextOfTableFields);
		QueryText = StrReplace(QueryText, "&TempTableName", TempTableName);
		RowsArray.Add(QueryText);
		
	EndDo; 
	
	If RowsArray.Count() <> 0 Then
		DataJoinText = StrConcat(RowsArray, TMCommonUse.QuerySeparatorInJoin());
		Return DataJoinText;
	EndIf; 
	
	Return "";

EndFunction

Function NavigateDocumentsInBackground(DocumentsList) Export

	For Each DocumentRef In DocumentsList Do
		DocumentObject = DocumentRef.GetObject();
		If DocumentObject = Undefined Or DocumentObject.DeletionMark Then
			Continue;
		EndIf; 
		DocumentObject.Write(DocumentWriteMode.Posting);
	EndDo; 

	CalculationResult2 = New Structure;
	CalculationResult2.Insert("HasErrors", False);
	CalculationResult2.Insert("ErrorText", "");

	Return CalculationResult2;
	
EndFunction

Procedure SetParametersOfFunctionalOptionsOfObjectForm(Form, Organization, Date, Periodicity = "MONTH") Export
	
	ParentCompany = AccountingPoliciesTaxSettingsCached.ParentCompany(Organization);
	
	FOParameters = New Structure("Organization, Period",
		ParentCompany, ?(Upper(Periodicity) = "MONTH", BegOfMonth(Date), BegOfDay(Date)));

	Form.SetFormFunctionalOptionParameters(FOParameters);

EndProcedure

Function ConditionsForSwitchingToAccounting2_4() Export

	Comment2_4 = "";
	ConditionsForEnablingAccounting2_4 = "";
	CommentMinStartDate2_4 = "";
	CommentMaxStartDate2_4 = "";
	
	MinimumAccountingStartDate2_4 = '000101010000';
	MaximumStartDateOfAccounting2_4 = '000101010000';
	
	BatchAccountingMode = True;
	KeepManagementRecordsOfOrganizations = True;
	UseAccountingOfOtherIncomeExpensesInLocalAccounting = True;
	
	If Not CalculationOfCostCached.BatchAccountingVersion22() Then
		BatchAccountingMode = False;
		ConditionsForEnablingAccounting2_4 = ConditionsForEnablingAccounting2_4 + Chars.LF
			+ NStr("vi = '- đặt tùy chọn ""Kế toán theo lô"" giá trị ""Phiên bản 2.2""
                    |(phân hệ ""Danh mục và quản trị"" - ""Kết quả kinh doanh và kiểm soát"")';
                    |ru = '- установить опции ""Партионный учет"" значение ""Версия 2.2""
                    |(раздел ""НСИ и администрирование"" - ""Финансовый результат и контроллинг"")';
                    |en = '- set the ""Version 2.2"" value to the ""Lot accounting"" option
                    |(in ""Master data and settings"" - ""Profitability & cost"")'; fa = '- set the ""Version 2.2"" value to the ""Lot accounting"" option
                    |(in ""Master data and settings"" - ""Profitability & cost"")';
                    |it = '- impostare le opzioni ""Contabilità di lotto"" valore ""Versione 2.2"" 
                    |(sezione ""Dati anagrafici e amministrazione"" - ""Risultato finanziario e controllo"")';
                    |pl = '- ustaw opcje ""Ewidencja partii"" wartość ""Wersja 2.2""
                    |(rozdział  ""Informacja normatywno-pomocnicza i administrowanie"" - ""Rezultat finansowy i kontrolowanie"")';
                    |tr = '- ""Toplu muhasebe"" seçeneklerini ""Sürüm 2.2""
                    | olarak ayarlayın (""Master veri ve yönetim"" - ""Finansal sonuç ve kontrol"" bölümü)'");
	Else
		DateOfOption = CalculationOfCostCached.DateOfMigrationToBatchAccounting22();
		If ValueIsFilled(DateOfOption) And DateOfOption > MinimumAccountingStartDate2_4 Then
			MinimumAccountingStartDate2_4 = DateOfOption;
			MessageTemplate = NStr("vi = 'Thời điểm bắt đầu kế toán không được sớm hơn ngày bắt đầu áp dụng đợt kế toán theo đợt 2.2: %1';
									|ru = 'Начало учета должно быть не раньше даты начала применения партионного учета версии 2.2: %1';
									|en = 'Accounting should not start earlier than lot accounting 2.2. start date: %1'; fa = 'Accounting should not start earlier than lot accounting 2.2. start date: %1';
									|it = 'L''inizio della contabilità dovrebbe essere non precedente alla data di inizio dell''applicazione della contabilità di lotto nella versione 2.2: %1';
									|pl = 'Początek ewidencji musi być nie wcześniej niż początek stosowania ewidencji partii wersji 2.2: %1';
									|tr = 'Muhasebe başlangıcı, toplu muhasebe sürüm 2.2 uygulamasının başlangıç tarihinden daha erken olmamalıdır: %1'");
			CommentMinStartDate2_4 = StrTemplate(MessageTemplate, Format(MinimumAccountingStartDate2_4, "DLF=D"));
		EndIf; 
	EndIf;

	If Not Constants.UseAccountingOfOtherIncomeExpensesInLocalAccounting.Get() Then
		UseAccountingOfOtherIncomeExpensesInLocalAccounting = False;
		ConditionsForEnablingAccounting2_4 = ConditionsForEnablingAccounting2_4 + Chars.LF
			+ NStr("vi = '- bật tùy chọn ""Thu nhập và chi phí khác theo tiền tệ kế toán tài chính""
                    |(phân hệ ""Danh mục và quản trị"" - ""Kết quả kinh doanh và kiểm soát"")';
                    |ru = '- включить опцию ""Прочие доходы и расходы в валюте регл. учета""
                    |(раздел ""НСИ и администрирование"" - ""Финансовый результат и контроллинг"")';
                    |en = '- enable the ""Income and expenses in local accounting currency"" option
                    |(in ""Master data and settings"" - ""Profitability & cost"")'; fa = '- enable the ""Income and expenses in local accounting currency"" option
                    |(in ""Master data and settings"" - ""Profitability & cost"")';
                    |it = '- abilitare opzione ""altre entrate e uscite nella valuta della contabilità reg.""
                    | (sezione ""Dati anagrafici e amministrazione"" - ""Risultato finanziario e controllo"")';
                    |pl = '- włącz opcje ""Inne dochody i rozchody w walucie ewidencji reglamentowanej""
                    |(rozdział ""Informacja normatywno-pomocnicza i administrowanie"" - ""Rezltat finansowy i kontrolowanie"")';
                    |tr = '- ""Yerel muhasebe para birimindeki diğer gelir ve giderler"" seçeneğini etkinleştirin."" 
                    |(""Master veri ve yönetim"" - ""Finansal sonuç ve kontrol"" bölümü)'");
	EndIf;

	If Not CalculationOfCostCached.CompanyManagementAccounting() Then
		KeepManagementRecordsOfOrganizations = False;
		ConditionsForEnablingAccounting2_4 = ConditionsForEnablingAccounting2_4 + Chars.LF
			+ NStr("vi = '- bật tùy chọn ""Kế toán quản trị theo quy tắc kế toán tài chính quốc tế""
                    |(phân hệ ""Danh mục và quản trị"" - ""Kết quả kinh doanh và kiểm soát"" - ""Tùy chỉnh bổ sung kế toán giá vốn"")';
                    |ru = '- включить опцию ""Управленческий учет по правилам международного финансового учета""
                    |(раздел ""НСИ и администрирование"" - ""Финансовый результат и контроллинг"" - ""Доп. настройки учета себестоимости"")';
                    |en = '- enable the ""Management accounting according to financial accounting rules"" option
                    | (in ""Master data and settings"" - ""Profitability & cost"" - ""Add. settings of cost accounting"")'; fa = '- enable the ""Management accounting according to financial accounting rules"" option
                    | (in ""Master data and settings"" - ""Profitability & cost"" - ""Add. settings of cost accounting"")';
                    |it = '- abilitare opzione ""Contabilità gestionale in base ai parametri della contabilità finanziaria internazionale""
                    |  (sezione ""Dati anagrafici e amministrazione"" - ""Risultato finanziario e controllo"") - ""Impostazioni aggiuntive pe rcalcolo del costo"")';
                    |pl = '- włącz opcję ""Ewidencja zarządcza wg reguł międzynarodowej ewidencji finansowej""
                    |(rozdział ""INP i administrowanie"" - ""Wynik finansowy i Controlling"" - ""Dodatkowe ustawienia ewidencji kosztów własnych"")';
                    |tr = '- ""Uluslararası muhasebe kurallarına göre yönetim muhasebesi"" seçeneğini etkinleştirin
                    | (""Master veri ve yönetim"" - ""Finansal sonuç ve kontrol"" - ""Ek maliyet muhasebesi ayarları"" bölümü)'");
	Else
		DateOfOption = CalculationOfCostCached.StartDateOfManagementAccountingOfOrganizations();
		If ValueIsFilled(DateOfOption) And DateOfOption > MinimumAccountingStartDate2_4 Then
			MinimumAccountingStartDate2_4 = DateOfOption;
			MessageTemplate = NStr("vi = 'Thời điểm bắt đầu kế toán không được sớm hơn ngày bắt đầu kế toán quản trị theo quy tắc kế toán tài chính quốc tế: %1';
									|ru = 'Начало учета должно быть не раньше даты начала ведения управленческого учета по правилам международного финансового учета: %1';
									|en = 'Accounting start date cannot be earlier than the start date of management accounting according to the financial accounting rules: %1'; fa = 'Accounting start date cannot be earlier than the start date of management accounting according to the financial accounting rules: %1';
									|it = 'L''inizio della contabilità dovrebbe essere non precedente alla data di inizio dell''applicazione della contabilità gestionale in base ai parametri della contabilità finanziaria internazionale: %1';
									|pl = 'Początek ewidencji musi być nie wcześniej daty początku prowadzenia ewidencji zarządczej według reguł miedzynarodowej ewidencji finansowej: %1';
									|tr = 'Muhasebenin başlangıcı, uluslararası muhasebe kurallarına göre yönetim muhasebesinin başladığı tarihten daha erken olmamalıdır: %1'");
			CommentMinStartDate2_4 = StrTemplate(MessageTemplate, Format(MinimumAccountingStartDate2_4, "DLF=D"));
		EndIf; 
	EndIf;
	
	NonCurrentAssetsLocalization.ConditionsForSwitchingToAccounting2_4(
		MinimumAccountingStartDate2_4, 
		CommentMinStartDate2_4,
		MaximumStartDateOfAccounting2_4, 
		CommentMaxStartDate2_4);
	
	If ValueIsFilled(ConditionsForEnablingAccounting2_4) Then
		Comment2_4 = NStr("vi = 'Để kích hoạt kế toán cho phiên bản 2.4, bạn phải:';
							|ru = 'Для включения возможности учета версии 2.4 необходимо:';
							|en = 'To enable accounting 2.4:'; fa = 'To enable accounting 2.4:';
							|it = 'Per abilitare la contabilità nella versione 2.4. è necessario:';
							|pl = 'Dla włączenia możliwości ewidencji wersji 2.4 należy:';
							|tr = 'Sürüm 2.4 muhasebe özelliğini etkinleştirmek için şunları yapmanız gereklidir:'") + ConditionsForEnablingAccounting2_4;
	EndIf; 
	
	AccountingAvailability2_4 = New Structure;
	AccountingAvailability2_4.Insert("BatchAccountingMode", BatchAccountingMode);
	AccountingAvailability2_4.Insert("KeepManagementRecordsOfOrganizations", KeepManagementRecordsOfOrganizations);
	AccountingAvailability2_4.Insert("UseAccountingOfOtherIncomeExpensesInLocalAccounting", UseAccountingOfOtherIncomeExpensesInLocalAccounting);
	
	AccountingAvailability2_4.Insert("Comment2_4", Comment2_4);
	AccountingAvailability2_4.Insert("ConditionsForEnablingAccounting2_4", ConditionsForEnablingAccounting2_4);
	AccountingAvailability2_4.Insert("CommentMinStartDate2_4", CommentMinStartDate2_4);
	AccountingAvailability2_4.Insert("CommentMaxStartDate2_4", CommentMaxStartDate2_4);
	AccountingAvailability2_4.Insert("MinimumAccountingStartDate2_4", MinimumAccountingStartDate2_4);
	AccountingAvailability2_4.Insert("MaximumStartDateOfAccounting2_4", MaximumStartDateOfAccounting2_4);
	AccountingAvailability2_4.Insert("AccountingIsAvailable", Not ValueIsFilled(Comment2_4));
	
	NonCurrentAssetsLocalization.AddConditionsForSwitchingToAccounting2_4(AccountingAvailability2_4);
	
	Return AccountingAvailability2_4;
	
EndFunction

Procedure ProcessFormParametersPassedFromMonthClose(Form) Export
	
	Items = Form.Items;
	Parameters = Form.Parameters;
	
	If Parameters.Property("CompanyArray") Then
		
		CompaniesList = New ValueList();
		CompaniesList.LoadValues(Parameters.CompanyArray); 
		
		CommonClientServer.SetDynamicListFilterItem(
			Form.List, 
			"Organization", 
			CompaniesList,,,,
			DataCompositionSettingsItemViewMode.Normal);
	EndIf;
	 
	If Parameters.Property("Period") Then
		ListPeriod_ = Items.List.Period; // StandardPeriod - 
		ListPeriod_.StartDate = BegOfMonth(Parameters.Period); 
		ListPeriod_.EndDate= EndOfMonth(Parameters.Period); 
	EndIf; 
	
EndProcedure

// Returns a list of documents in the VNA subsystem.
// 
// Returns:
// 	Array of String - List of documents of the VNA subsystem.
//
Function ListOfVNADocuments() Export
	
	ListOfVNADocuments = New Array;
	LeasedAssetAccounting.ListOfSubsystemDocuments(ListOfVNADocuments);
	
	ListOfVNADocuments.Add(Metadata.Documents.IntangibleAssetsAmortizationCharge2_4.Name);
	ListOfVNADocuments.Add(Metadata.Documents.FixedAssetsDepreciationCharge2_4.Name);
	ListOfVNADocuments.Add(Metadata.Documents.EntryOfCapitalAssetsBalance2_4.Name);
	ListOfVNADocuments.Add(Metadata.Documents.OBEntrySubAssetsAndComponentsOfDepreciation.Name);
	ListOfVNADocuments.Add(Metadata.Documents.ReturnAssetsFromLeasee2_4.Name);
	ListOfVNADocuments.Add(Metadata.Documents.ReturnLeasedAssets.Name);
	ListOfVNADocuments.Add(Metadata.Documents.IntangibleAssetsOperatingTime.Name);
	ListOfVNADocuments.Add(Metadata.Documents.ChangeIntangibleAssetFinancialDetails2_4.Name);
	ListOfVNADocuments.Add(Metadata.Documents.ChangeFixedAssetFinancialDetails2_4.Name);
	ListOfVNADocuments.Add(Metadata.Documents.IntangibleAssetsPhysicalCount.Name);
	ListOfVNADocuments.Add(Metadata.Documents.FixedAssetsPhysicalCount.Name);
	ListOfVNADocuments.Add(Metadata.Documents.IntangibleAssetsCostAndAmortizationAdjustment.Name);
	ListOfVNADocuments.Add(Metadata.Documents.FixedAssetCostAndDepreciationAdjustment.Name);
	ListOfVNADocuments.Add(Metadata.Documents.FixedAssetsCostAdditions2_4.Name);
	ListOfVNADocuments.Add(Metadata.Documents.ImpairmentFA.Name);
	ListOfVNADocuments.Add(Metadata.Documents.MergeOfFixedAssets.Name);
	ListOfVNADocuments.Add(Metadata.Documents.AllocateVariancesToFixedAssetCost.Name);
	ListOfVNADocuments.Add(Metadata.Documents.ProvideAssetsToLeasee2_4.Name);
	ListOfVNADocuments.Add(Metadata.Documents.IATransfer2_4.Name);
	ListOfVNADocuments.Add(Metadata.Documents.FATransfer2_4.Name);
	ListOfVNADocuments.Add(Metadata.Documents.IARevaluation2_4.Name);
	ListOfVNADocuments.Add(Metadata.Documents.FARevaluation2_4.Name);
	ListOfVNADocuments.Add(Metadata.Documents.PreparingForIntangibleAssetSale2_4.Name);
	ListOfVNADocuments.Add(Metadata.Documents.PreparingForFixedAssetSale2_4.Name);
	ListOfVNADocuments.Add(Metadata.Documents.ReceiveLeasedAssets.Name);
	ListOfVNADocuments.Add(Metadata.Documents.RDExpenseRecognition.Name);
	ListOfVNADocuments.Add(Metadata.Documents.IntangibleAssetsInitialRecognition2_4.Name);
	ListOfVNADocuments.Add(Metadata.Documents.FixedAssetsInitialRecognition2_4.Name);
	ListOfVNADocuments.Add(Metadata.Documents.RecognizeSubAssetsComponentsOfDepreciation.Name);
	ListOfVNADocuments.Add(Metadata.Documents.SplitFixedAssets.Name);
	ListOfVNADocuments.Add(Metadata.Documents.DisposeIntangibleAssets2_4.Name);
	ListOfVNADocuments.Add(Metadata.Documents.DisposeFixedAssets2_4.Name);
	ListOfVNADocuments.Add(Metadata.Documents.IntangibleAssetImprovement.Name);
	
	Return ListOfVNADocuments;
	
EndFunction

// Sets the parameters for selecting an article in the order of accounting.
// 
// Parameters:
//  ChoiceParameters - FixedArray of ChoiceParameter - The selection parameters
//  ChoiceParametersValues - Structure - Values of the selection parameters
Procedure SetArticleSelectionParametersByAccountingOrder(ChoiceParameters, ChoiceParametersValues) Export
	
	NewSelectionOptions = New Array;
	For Each Item In ChoiceParameters Do
		If Upper(Item.Name) <> Upper("Filter.CostAllocationOptionManag")
			And Upper(Item.Name) <> Upper("Filter.CostAllocationOptionLocal")
			And Upper(Item.Name) <> Upper("Filter.CostAllocationOptionTax") Then
			NewSelectionOptions.Add(Item);
		EndIf;
	EndDo;
	
	AccountingProcedureAC = CommonClientServer.StructureProperty(ChoiceParametersValues, "AccountingProcedureAC", Undefined);
	AccountingProcedureMA = CommonClientServer.StructureProperty(ChoiceParametersValues, "AccountingProcedureMA", Undefined);
	AccountingProcedureTA = CommonClientServer.StructureProperty(ChoiceParametersValues, "AccountingProcedureTA", Undefined);
	
	DistributionOptions = NonCurrentAssetsClientServer.AvailableCostSharingOptions(AccountingProcedureMA);
	If DistributionOptions.Count() <> 0 Then
		Item = New ChoiceParameter("Filter.CostAllocationOptionManag", DistributionOptions);
		NewSelectionOptions.Add(Item);
	EndIf; 
	
	DistributionOptions = NonCurrentAssetsClientServer.AvailableCostSharingOptions(AccountingProcedureAC);
	If DistributionOptions.Count() <> 0 Then
		Item = New ChoiceParameter("Filter.CostAllocationOptionLocal", DistributionOptions);
		NewSelectionOptions.Add(Item);
	EndIf; 
	
	DistributionOptions = NonCurrentAssetsClientServer.AvailableCostSharingOptions(AccountingProcedureTA);
	If DistributionOptions.Count() <> 0 Then
		Item = New ChoiceParameter("Filter.CostAllocationOptionTax", DistributionOptions);
		NewSelectionOptions.Add(Item);
	EndIf; 
	
	ChoiceParameters = New FixedArray(NewSelectionOptions);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region AccessManagement

Procedure AddAccountantProfileForNonCurrentAssets(ProfilesDetails)
	
	// Profile "Accountant for non-current assets".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "NonCurrentAssetsAccountant";
	ProfileDetails.Id = "ddb10492-ea5e-11e3-b754-c86000df10d3";
	ProfileDetails.Parent      = "Finances";
	ProfileDetails.Description  = NStr("vi = 'Kế toán tài sản dài hạn';
										|ru = 'Бухгалтер по внеоборотным активам';
										|en = 'Fixed asset accountant'; fa = 'Fixed asset accountant';
										|it = 'Contabile degli attivi non circolanti';
										|pl = 'Księgowy ds aktywów trwałych';
										|tr = 'Duran varlıklara ilişkin muhasebeci'", Common.DefaultLanguageCode());
	
	CAAccessManagement.AddRequiredRolesToYourProfile(ProfileDetails);
	
	AddRolesToAccessSubsystemInResponseToChange(ProfileDetails);
	LeasedAssetAccounting.AddRolesToAccessSubsystemInResponseToChange(ProfileDetails);
	
	// Reference books, appendix.
	ProfileDetails.Roles.Add("AddEditLabelsTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("AddEditRDStagesTopics");
	
	// Other reference books, reading.
	ProfileDetails.Roles.Add("ReadCounterpartyContracts");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadOtherTransactionsGLAccountsSettings");
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadRunningTimeValues");
	ProfileDetails.Roles.Add("ReadTermsOfSales");
	ProfileDetails.Roles.Add("ReadTermsOfPurchases");
	ProfileDetails.Roles.Add("ReadOperationCategories");
	ProfileDetails.Roles.Add("ReadPriorities");
	ProfileDetails.Roles.Add("ViewLimitsForBudgetingData");
	ProfileDetails.Roles.Add("ReadMaintenanceSchemes");
	ProfileDetails.Roles.Add("ReadSubAssets");
	// Documents, appendix.
	ProfileDetails.Roles.Add("AddEditInventoryConsumption");
	ProfileDetails.Roles.Add("AddEditVendorInvoiceServicesAndAssets");
	ProfileDetails.Roles.Add("AddEditProvisionRequests");
	ProfileDetails.Roles.Add("AddEditOtherGoodsReceipt");
	ProfileDetails.Roles.Add("AddEditCustomerInvoiceServicesAndAssets");
	ProfileDetails.Roles.Add("AddEditApplicationsForGoodsImport");
	
	// Other documents, reading.
	ProfileDetails.Roles.Add("ReadInventoryConsumptionOrders");
	ProfileDetails.Roles.Add("ReadVendorInvoicesReturnsToVendors");
	
	// Reports and processing.
	ProfileDetails.Roles.Add("UseDataProcessorInternalInventoryTransferLog");
	ProfileDetails.Roles.Add("UsingDataProcessorPrintLabelsOfInventoryInOperation");
	ProfileDetails.Roles.Add("ViewOfStepsOfPaymentToVendor");
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	
	// Reading registers.
	
	// Reading other registers.
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadBalanceOfInventoryConsumptionOrders");
	ProfileDetails.Roles.Add("ReadStockBalanceToShip");
	ProfileDetails.Roles.Add("ReadStockOnWarehouses");
	ProfileDetails.Roles.Add("ReadOtherAssetsAndLiabilities");
	ProfileDetails.Roles.Add("ReadOtherIncomeAndExpenses");
	ProfileDetails.Roles.Add("ReadDeliveryStates");
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadInventoryInOperation");
	ProfileDetails.Roles.Add("ReadVATRegisters");
	ProfileDetails.Roles.Add("ReadExciseRecords");
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	// Types of access.
	ProfileDetails.AccessKinds.Add("Companies", "AllAllowedByDefault");
	
	NonCurrentAssetsLocalization.SupplementAccountantForNonCurrentAssetsProfile(ProfileDetails);
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = 
		NStr("vi = 'Hồ sơ bổ sung được chỉ định cho người dùng để thực hiện các nhiệm vụ kế toán tài sản dài hạn:
		|1. Duy trì thông tin tham khảo
		|2. Nhập chứng từ biến động tài sản dài hạn
		|3. Nhận báo cáo theo dữ liệu kế toán doanh nghiệp và kế toán thuế.';
		|ru = 'Дополнительный профиль, назначаемый пользователям для выполнения задач учета внеоборотных активов:
		|1. Сопровождения нормативно-справочной информации
		|2. Ведения документов движений внеоборотных активов
		|3. Получение отчетов по данным бухгалтерского и налогового учета.';
		|en = 'Additional profile assigned to users to execute tasks of fixed assets accounting:
		|1. Support master data
		|2. Keep a record of documents of fixed asset movements
		|3. Receive reports on local accounting and tax accounting data.'; fa = 'Additional profile assigned to users to execute tasks of fixed assets accounting:
		|1. Support master data
		|2. Keep a record of documents of fixed asset movements
		|3. Receive reports on local accounting and tax accounting data.';
		|it = 'Profilo aggiuntivo assegnato agli utenti per le attività di contabilizzazione degli attivi non circolanti:
		| 1. Manutenzione delle informazioni di riferimento; 
		|2. Mantenimento di documenti relativi a movimenti di attivi non circolanti; 
		|3. Ricezione di report su dati contabili e fiscali.';
		|pl = 'Dodatkowy profil, możliwość przypisania użytkowników do wykonywania zadań rachunkowości trwałych aktywów:
		|1. Prowadzenie regulacyjno-poradniczej informacji
		|2. Prowadzenia dokumentów ruchów trwałych aktywów
		|3. Uzyskiwanie raportów na podstawie danych z ewidencji księgowej i podatkowej.';
		|tr = 'Duran varlıklar muhasebesi görevlerini gerçekleştirmek için kullanıcılara atanan ek bir profil: 
		| 1. Normatif ve referans bilgilerin desteklenmesi 
		| 2. Duran varlık hareketlerinin belgelerinin tutulması 
		| 3. Muhasebe ve vergi muhasebesi verilerine ilişkin raporların alınması.'");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure AddProfileResponsibleForMaintainingOperationalFacilities(ProfilesDetails)
	
	// Profile "Responsible for maintenance of operational facilities (additional)".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name = "ResponsibleForMaintenanceOfFacilities";
	ProfileDetails.Id = "4871ded3-fdd7-4616-a7fd-c373544d7af5";
	ProfileDetails.Parent = "MasterDataAndSettings";
	ProfileDetails.Description = NStr("vi = 'Chịu trách nhiệm quản lý các đối tượng vận hành (bổ sung)';
										|ru = 'Ответственный за ведение объектов эксплуатации (дополнительный)';
										|en = 'Employee responsible for assets (additional)'; fa = 'Employee responsible for assets (additional)';
										|it = 'Responsabile per la gestione di oggetti d''uso operativo (aggiuntivo)';
										|pl = 'Odpowiedzialny za prowadzenie obiektów eksploatacji (dodatkowy)';
										|tr = 'Kullanım nesnelerinin bakımından sorumludur (ek)'", Common.DefaultLanguageCode());
	
	// Applied rights.
	ProfileDetails.Roles.Add("AddEditAssets");
	ProfileDetails.Roles.Add("AddEditLabelsTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("AddEditSubAssets");
	ProfileDetails.Roles.Add("AddEditMaintenanceSchemes");
	// Types of access.
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");

	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Hồ sơ bổ sung được chỉ định bởi người sử dụng, quản lý danh mục ""Tài sản đang vận hành"".';
									|ru = 'Дополнительный профиль, назначается пользователям, ведущим справочник ""Объекты эксплуатации"".';
									|en = 'Additional profile is assigned to users keeping the ""Assets"" catalog.'; fa = 'Additional profile is assigned to users keeping the ""Assets"" catalog.';
									|it = 'Account aggiuntivo, viene assegnato agli utenti che gestiscono la directory ""Oggetti d''uso operativo"".';
									|pl = 'Dodatkowy profil, jest przypisywany użytkownikom, prowadzącym katalog ""Obiekty eksploatacji"".';
									|tr = '""Kullanım nesneleri"" dizinini tutan kullanıcılara atanan ek profil.'");
	                                      
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

#EndRegion

#Region PerformMonthEndClosingOperations

// Creates a job queue table.
// 
// Returns:
//  ValueTable - contains fields:
//  	* JobID - UUID -
//  	* ResultAddress - String -
//  	* BackgroundJobDescription - String
//  	* Status - String -
//  	* CalculationProcedure_ - String -
//  	* WaitCompletion - Number -
//  	* JobParameters - Structure -
//
Function InitiateTaskQueue() Export
	
	TaskQueue = New ValueTable;
	TaskQueue.Columns.Add("JobID", New TypeDescription("UUID"));
	TaskQueue.Columns.Add("ResultAddress", New TypeDescription("String"));
	TaskQueue.Columns.Add("BackgroundJobDescription", New TypeDescription("String"));
	TaskQueue.Columns.Add("Status", New TypeDescription("String"));
	TaskQueue.Columns.Add("CalculationProcedure_", New TypeDescription("String"));
	TaskQueue.Columns.Add("WaitCompletion", New TypeDescription("Number"));
	TaskQueue.Columns.Add("JobParameters");
	
	Return TaskQueue;
	
EndFunction

// Executes a queue of tasks.
// 
// Parameters:
//  TaskQueue - See InitiateTaskQueue
//  MaximumTasks - Number - Maximum Tasks
//  CalculationID - UUID - calculation ID
//  RunInBackground - Boolean - Launch in the background
// 
// Returns:
//  Structure -  Execute Task Queue:
// 		* HasErrors - Boolean - 
// 		* ErrorText - String - 
// 		* DataVolume - Number - 
Function ExecuteTaskQueue(TaskQueue, MaximumTasks, CalculationID, RunInBackground = True) Export

	TasksInProgress_ = 0;
	
	HasJobs = True;
	
	ExecutionResult = New Structure;
	ExecutionResult.Insert("HasErrors", False);
	ExecutionResult.Insert("ErrorText", "");
	ExecutionResult.Insert("DataVolume", 0);
	
	While HasJobs Do
		
		HasJobs = False;
		
		For Each JobDetails In TaskQueue Do
			
			If JobDetails.Status = "" 
				And TasksInProgress_ < MaximumTasks Then
				
				// Starting a new task until the maximum tasks are exceeded
				
				BackgroundExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(New UUID);
				BackgroundExecutionParameters.BackgroundJobDescription = JobDetails.BackgroundJobDescription;
				BackgroundExecutionParameters.RunNotInBackground1 = Not RunInBackground;
				
				JobCompletingResult = TimeConsumingOperations.ExecuteFunction(
												BackgroundExecutionParameters, 
												JobDetails.CalculationProcedure_,
												JobDetails.JobParameters);
				
				MonthEndTransactionsServer.SubordinateBackgroundTaskOfCalculationStageHasBeenStarted(
					CalculationID, JobCompletingResult.JobID);
				
				JobDetails.WaitCompletion = BackgroundExecutionParameters.WaitCompletion;
				JobDetails.Status = JobCompletingResult.Status;
				JobDetails.JobID = JobCompletingResult.JobID;
				JobDetails.ResultAddress = JobCompletingResult.ResultAddress;
				
				If JobDetails.Status = "Running" Then
					TasksInProgress_ = TasksInProgress_ + 1;
				ElsIf JobDetails.Status = "Error" Then
					ExecutionResult.HasErrors = True;
					ExecutionResult.ErrorText = JobCompletingResult.DetailErrorDescription;
				EndIf;
				
			ElsIf JobDetails.Status = "Running" Then
				
				// Checking the execution
				
				Job = BackgroundJobs.FindByUUID(JobDetails.JobID);
				If Job <> Undefined 
					And Job.State = BackgroundJobState.Active Then
					
					Job = Job.WaitForExecutionCompletion(JobDetails.WaitCompletion);
					If Job.State <> BackgroundJobState.Active Then
						JobDetails.Status = "Completed2";
						TasksInProgress_ = TasksInProgress_ - 1;
					EndIf;
					
				ElsIf Job = Undefined 
					Or Job.State = BackgroundJobState.Failed
					Or Job.State = BackgroundJobState.Canceled Then
					
					ExecutionResult.HasErrors = True;
					
					JobDetails.Status = "Error";
					TasksInProgress_ = TasksInProgress_ - 1;
					
				ElsIf Job.State = BackgroundJobState.Completed Then
					
					JobDetails.Status = "Completed2";
					TasksInProgress_ = TasksInProgress_ - 1;
					
				EndIf; 
				
			EndIf; 
			
			If JobDetails.Status = "Completed2" 
				And IsTempStorageURL(JobDetails.ResultAddress) Then
				
				DataVolume = GetFromTempStorage(JobDetails.ResultAddress);
				If DataVolume <> Undefined Then
					ExecutionResult.DataVolume = ExecutionResult.DataVolume + DataVolume;
				EndIf;
				
				JobDetails.ResultAddress = Undefined;
				
			EndIf;
			
			If JobDetails.Status = "Running" 
				Or JobDetails.Status = "" Then
				
				HasJobs = True;
			EndIf;
			
		EndDo; 
		
	EndDo; 
	
	Return ExecutionResult;
	
EndFunction

// Generates a table based on the calculation.
// 
// Parameters:
//  BeginOfPeriod - Date - Beginning of the period
//  EndOfPeriod - Date - End of the period
//  CompaniesList - Array of CatalogRef.Companies - List of organizations
//  DocumentIDs - Array of CatalogRef.MetadataObjectIDs - Document IDs
//  TempTablesManager - TempTablesManager - temporary table Manager
Procedure CreateTTTableWithAllDataToBeCalculated(BeginOfPeriod, EndOfPeriod, CompaniesList, DocumentIDs, TempTablesManager) Export

	QueryText =
	"SELECT
	|	AllDocuments.Ref AS Ref,
	|	AllDocuments.Date AS Date,
	|	AllDocuments.Organization AS Organization,
	|	CAST(AllDocuments.Organization AS Catalog.Companies).ParentCompany AS ParentCompany,
	|	AllDocuments.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	AllDocuments.RecordInManAccounting AS RecordInManAccounting,
	|	AllDocuments.BusinessOperation AS BusinessOperation,
	|	AllDocuments.AccountingObject AS AccountingObject,
	|
	|	CASE
	|		WHEN VALUETYPE(AllDocuments.Ref) = TYPE(Document.CustomerInvoiceServicesAndAssets)
	|				OR VALUETYPE(AllDocuments.Ref) = TYPE(Document.DisposeFixedAssets2_4)
	|				OR VALUETYPE(AllDocuments.Ref) = TYPE(Document.DisposeIntangibleAssets2_4)
	|			THEN 999999
	|		ELSE HOUR(AllDocuments.Date)*10000 + MINUTE(AllDocuments.Date)*100 + SECOND(AllDocuments.Date)
	|	END AS Priority
	|
	|INTO TTAllDataToBeCalculated
	|
	|FROM
	|	(SELECT
	|		CurrentDocuments.Ref AS Ref,
	|		CurrentDocuments.Date AS Date,
	|		CurrentDocuments.Organization AS Organization,
	|		CurrentDocuments.RecordInLocalAccounting AS RecordInLocalAccounting,
	|		CurrentDocuments.RecordInManAccounting AS RecordInManAccounting,
	|		CurrentDocuments.BusinessOperation AS BusinessOperation,
	|		CurrentDocuments.FixedAsset AS AccountingObject
	|	FROM
	|		InformationRegister.FixedAssetsDocuments AS CurrentDocuments
	|
	|	WHERE
	|		CurrentDocuments.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND CurrentDocuments.Organization IN (&CompaniesList)
	|		AND CurrentDocuments.RefType IN (&DocumentIDs)
	|		AND CurrentDocuments.Posted
	|
	|		AND CurrentDocuments.FixedAsset IN (
	|				SELECT
	|					ListOfObjects.AccountingObject
	|				FROM
	|					ListOfObjects AS ListOfObjects)
	|
	|		AND (NOT CurrentDocuments.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice),
	|				VALUE(Enum.BusinessTransactions.ProvideAssetsToLeasee))
	|			OR NOT CurrentDocuments.AdditionalRecord)
	|
	|	UNION ALL
	|
	|	SELECT
	|		CurrentDocuments.Ref AS Ref,
	|		CurrentDocuments.Date AS Date,
	|		CurrentDocuments.Organization AS Organization,
	|		CurrentDocuments.RecordInLocalAccounting AS RecordInLocalAccounting,
	|		CurrentDocuments.RecordInManAccounting AS RecordInManAccounting,
	|		CurrentDocuments.BusinessOperation AS BusinessOperation,
	|		CurrentDocuments.IntangibleAsset AS AccountingObject
	|	FROM
	|		InformationRegister.IntangibleAssetsDocuments AS CurrentDocuments
	|
	|	WHERE
	|		CurrentDocuments.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND CurrentDocuments.Organization IN (&CompaniesList)
	|		AND CurrentDocuments.RefType IN (&DocumentIDs)
	|		AND CurrentDocuments.Posted
	|
	|		AND CurrentDocuments.IntangibleAsset IN (
	|				SELECT
	|					ListOfObjects.AccountingObject
	|				FROM
	|					ListOfObjects AS ListOfObjects)
	|
	|		AND (NOT CurrentDocuments.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice))
	|			OR NOT CurrentDocuments.AdditionalRecord)
	|
	|	UNION ALL
	|
		// The sub-assets of the FA-owner
	|	SELECT
	|		CurrentDocuments.Ref AS Ref,
	|		CurrentDocuments.Date AS Date,
	|		CurrentDocuments.Organization AS Organization,
	|		CurrentDocuments.RecordInLocalAccounting AS RecordInLocalAccounting,
	|		CurrentDocuments.RecordInManAccounting AS RecordInManAccounting,
	|		CurrentDocuments.BusinessOperation AS BusinessOperation,
	|		SubAssetsComponentsOfDepreciation.SubAssetComponent AS AccountingObject
	|
	|	FROM
	|		InformationRegister.FixedAssetsDocuments AS CurrentDocuments
	|
	|			INNER JOIN InformationRegister.SubAssetsComponentsOfDepreciation AS SubAssetsComponentsOfDepreciation
	|			ON SubAssetsComponentsOfDepreciation.FixedAsset = CurrentDocuments.FixedAsset
	|
	|	WHERE
	|		CurrentDocuments.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND CurrentDocuments.Organization IN (&CompaniesList)
	|		AND CurrentDocuments.RefType IN (&DocumentIDs)
	|		AND CurrentDocuments.Posted
	|
	|		AND CurrentDocuments.FixedAsset IN (
	|				SELECT
	|					ListOfObjects.AccountingObject
	|				FROM
	|					ListOfObjects AS ListOfObjects)
	|
	|		AND (NOT CurrentDocuments.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice),
	|				VALUE(Enum.BusinessTransactions.ProvideAssetsToLeasee))
	|			OR NOT CurrentDocuments.AdditionalRecord)
	|
	|	UNION ALL
	|
		// FA-owners of the sub-asset 
	|	SELECT
	|		CurrentDocuments.Ref AS Ref,
	|		CurrentDocuments.Date AS Date,
	|		CurrentDocuments.Organization AS Organization,
	|		CurrentDocuments.RecordInLocalAccounting AS RecordInLocalAccounting,
	|		CurrentDocuments.RecordInManAccounting AS RecordInManAccounting,
	|		CurrentDocuments.BusinessOperation AS BusinessOperation,
	|		SubAssetsComponentsOfDepreciation.FixedAsset AS AccountingObject
	|
	|	FROM
	|		InformationRegister.FixedAssetsDocuments AS CurrentDocuments
	|
	|			INNER JOIN InformationRegister.SubAssetsComponentsOfDepreciation AS SubAssetsComponentsOfDepreciation
	|			ON SubAssetsComponentsOfDepreciation.SubAssetComponent = CurrentDocuments.FixedAsset
	|				AND SubAssetsComponentsOfDepreciation.FixedAsset <> VALUE(Catalog.Assets.EmptyRef)
	|
	|	WHERE
	|		CurrentDocuments.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND CurrentDocuments.Organization IN (&CompaniesList)
	|		AND CurrentDocuments.RefType IN (&DocumentIDs)
	|		AND CurrentDocuments.Posted
	|
	|		AND CurrentDocuments.FixedAsset IN (
	|				SELECT
	|					ListOfObjects.AccountingObject
	|				FROM
	|					ListOfObjects AS ListOfObjects)
	|
	|		AND (NOT CurrentDocuments.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice),
	|				VALUE(Enum.BusinessTransactions.ProvideAssetsToLeasee))
	|			OR NOT CurrentDocuments.AdditionalRecord)
	|
	|	UNION ALL
	|
		// Object of construction
	|	SELECT
	|		CurrentDocuments.Recorder AS Ref,
	|		CurrentDocuments.Period AS Date,
	|		CurrentDocuments.Organization AS Organization,
	|		CurrentDocuments.RecordInLocalAccounting AS RecordInLocalAccounting,
	|		CurrentDocuments.RecordInManAccounting AS RecordInManAccounting,
	|		CurrentDocuments.BusinessOperation AS BusinessOperation,
	|		CurrentDocuments.ExpensesCapitalizationDimension AS AccountingObject
	|
	|	FROM
	|		AccumulationRegister.FACost AS CurrentDocuments
	|
	|			INNER JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|			ON DocumentsRegistry.Ref = CurrentDocuments.Recorder
	|
	|	WHERE
	|		CurrentDocuments.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND CurrentDocuments.Organization IN (&CompaniesList)
	|		AND DocumentsRegistry.RefType IN (&DocumentIDs)
	|		AND CurrentDocuments.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND CurrentDocuments.DimensionKindExpenseCapitalization = VALUE(Enum.KindsOfExpenseCapitalizationDimension.ConstructionObject)
	|		AND CurrentDocuments.ExpensesCapitalizationDimension <> UNDEFINED
	|		AND CurrentDocuments.Active
	|
	|		AND CurrentDocuments.FixedAsset IN (
	|				SELECT
	|					ListOfObjects.AccountingObject
	|				FROM
	|					ListOfObjects AS ListOfObjects)
	|
	|	) AS AllDocuments
	|
	|INDEX BY
	|	AccountingObject
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", EndOfPeriod);
	Query.SetParameter("CompaniesList", CompaniesList);
	Query.SetParameter("DocumentIDs", DocumentIDs);
	
	Query.Execute();
	
EndProcedure

// Generates a table of the portion of the data according to the calculation.
// 
// Parameters:
//  BeginOfPeriod - Date - Beginning of the period
//  TempTablesManager - TempTablesManager - temporary table Manager
//  DataChunkSize - Number - 
//  BusinessTransactions - Array -
// 
// Returns:
//  Number - Number Of Data To Be Calculated
Function CreateTTTablePortionOfDataToBeCalculated(BeginOfPeriod, TempTablesManager, DataChunkSize = 100, BusinessTransactions = Undefined) Export
	
	TTUsed = TMCommonUse.ListOfTemporaryTables(TempTablesManager);
	TTUsed.Add("TTPortionOfDataToBeCalculated");

	If BusinessTransactions = Undefined Then
		BusinessTransactions = New Array;
	EndIf;
	
	ListOfRequests = New Array;
	
	If TempTablesManager.Tables.Find("ProcessedOneData") = Undefined Then
		
		QueryText = 
		"SELECT
		|	UNDEFINED AS Ref,
		|	UNDEFINED AS AccountingObject,
		|	FALSE AS HasErrors
		|INTO ProcessedOneData
		|
		|INDEX BY
		|	Ref
		|";
		ListOfRequests.Add(QueryText);
		
		TTUsed.Add("ProcessedOneData");
		
	EndIf;
	
	If TempTablesManager.Tables.Find("TTPortionOfDataToBeCalculated") <> Undefined Then
		QueryText = 
		"DROP TTPortionOfDataToBeCalculated";
		ListOfRequests.Add(QueryText);
	EndIf;
	
	QueryText =
	"SELECT
	|	TTAllDataToBeCalculated.Ref AS Ref,
	|	TTAllDataToBeCalculated.Date AS Date,
	|	TTAllDataToBeCalculated.Organization AS Organization,
	|	TTAllDataToBeCalculated.ParentCompany AS ParentCompany,
	|	TTAllDataToBeCalculated.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	TTAllDataToBeCalculated.RecordInManAccounting AS RecordInManAccounting,
	|	TTAllDataToBeCalculated.BusinessOperation AS BusinessOperation,
	|	TTAllDataToBeCalculated.AccountingObject AS AccountingObject,
	|	TTAllDataToBeCalculated.Priority AS Priority
	|
	|INTO TTRawDataToBeCalculated
	|
	|FROM
	|	TTAllDataToBeCalculated AS TTAllDataToBeCalculated
	|
	|WHERE
	|	TTAllDataToBeCalculated.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND (TTAllDataToBeCalculated.BusinessOperation IN (&BusinessTransactions)
	|		OR NOT &FilterByBusinessTransaction)
	|
	// The document has not been processed
	|	AND NOT TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				ProcessedOneData AS ProcessedOneData
	|			WHERE
	|				ProcessedOneData.Ref = TTAllDataToBeCalculated.Ref)
	|
	|INDEX BY
	|	AccountingObject,
	|	Date
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 50 DISTINCT
	|	CurrentDataForCalculation.Ref AS Ref,
	|	CurrentDataForCalculation.Date AS Date,
	|	CurrentDataForCalculation.Organization AS Organization,
	|	CurrentDataForCalculation.ParentCompany AS ParentCompany,
	|	CurrentDataForCalculation.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	CurrentDataForCalculation.RecordInManAccounting AS RecordInManAccounting,
	|	CurrentDataForCalculation.BusinessOperation AS BusinessOperation,
	|	CurrentDataForCalculation.AccountingObject AS AccountingObject,
	|	CurrentDataForCalculation.Priority AS Priority
	|
	|INTO TTPortionOfDataToBeCalculatedPreliminary
	|
	|FROM
	|	TTRawDataToBeCalculated AS CurrentDataForCalculation
	|
	|WHERE
	// There are no earlier documents on any of the objects of the current document
	|	NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTRawDataToBeCalculated AS AllDocumentObjects
	|
	|				INNER JOIN TTRawDataToBeCalculated AS PreviousDataForCalculation
	|				ON PreviousDataForCalculation.AccountingObject = AllDocumentObjects.AccountingObject
	|					AND PreviousDataForCalculation.Ref <> AllDocumentObjects.Ref
	|
	|		WHERE
	|			AllDocumentObjects.Ref = CurrentDataForCalculation.Ref
	|
	|			AND (PreviousDataForCalculation.Date < AllDocumentObjects.Date
	|				OR PreviousDataForCalculation.Date = AllDocumentObjects.Date
	|					AND PreviousDataForCalculation.Priority < AllDocumentObjects.Priority
	|				OR PreviousDataForCalculation.Date = AllDocumentObjects.Date
	|					AND PreviousDataForCalculation.Priority = AllDocumentObjects.Priority
	|					AND PreviousDataForCalculation.Ref < AllDocumentObjects.Ref))
	|
	|INDEX BY
	|	AccountingObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CurrentDataForCalculation.Ref AS Ref,
	|	CurrentDataForCalculation.Date AS Date,
	|	CurrentDataForCalculation.Date AS Period,
	|	CurrentDataForCalculation.Organization AS Organization,
	|	CurrentDataForCalculation.ParentCompany AS ParentCompany,
	|	CurrentDataForCalculation.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	CurrentDataForCalculation.RecordInManAccounting AS RecordInManAccounting,
	|	CurrentDataForCalculation.BusinessOperation AS BusinessOperation,
	|	CurrentDataForCalculation.AccountingObject AS AccountingObject,
	|	CurrentDataForCalculation.Priority AS Priority
	|
	|INTO TTPortionOfDataToBeCalculated
	|
	|FROM
	|	(SELECT
	|		CurrentDataForCalculation.Ref AS Ref,
	|		CurrentDataForCalculation.Date AS Date,
	|		CurrentDataForCalculation.Organization AS Organization,
	|		CurrentDataForCalculation.ParentCompany AS ParentCompany,
	|		CurrentDataForCalculation.RecordInLocalAccounting AS RecordInLocalAccounting,
	|		CurrentDataForCalculation.RecordInManAccounting AS RecordInManAccounting,
	|		CurrentDataForCalculation.BusinessOperation AS BusinessOperation,
	|		CurrentDataForCalculation.AccountingObject AS AccountingObject,
	|		CurrentDataForCalculation.Priority AS Priority
	|	FROM
	|		TTPortionOfDataToBeCalculatedPreliminary AS CurrentDataForCalculation
	|
	|	UNION ALL
	|
	|	SELECT
	|		CurrentDataForCalculation.Ref AS Ref,
	|		CurrentDataForCalculation.Date AS Date,
	|		CurrentDataForCalculation.Organization AS Organization,
	|		CurrentDataForCalculation.ParentCompany AS ParentCompany,
	|		CurrentDataForCalculation.RecordInLocalAccounting AS RecordInLocalAccounting,
	|		CurrentDataForCalculation.RecordInManAccounting AS RecordInManAccounting,
	|		CurrentDataForCalculation.BusinessOperation AS BusinessOperation,
	|		CurrentDataForCalculation.AccountingObject AS AccountingObject,
	|		CurrentDataForCalculation.Priority AS Priority
	|	FROM
	|		TTRawDataToBeCalculated AS CurrentDataForCalculation
	|
	|			INNER JOIN Document.RecognizeSubAssetsComponentsOfDepreciation.DepreciationComponents AS FATable
	|			ON FATable.Ref = CurrentDataForCalculation.Ref
	|
	|	WHERE
	|		VALUETYPE(CurrentDataForCalculation.Ref) = TYPE(Document.RecognizeSubAssetsComponentsOfDepreciation)
	|
	|		AND TRUE IN (
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				TTPortionOfDataToBeCalculatedPreliminary AS T
	|			WHERE
	|				VALUETYPE(T.Ref) = TYPE(Document.FixedAssetsInitialRecognition2_4)
	|				AND T.AccountingObject = FATable.FixedAsset
	|				AND T.Date >= BEGINOFPERIOD(CurrentDataForCalculation.Date, MONTH)
	|				AND T.Date <= ENDOFPERIOD(CurrentDataForCalculation.Date, MONTH))
	|
	|	) AS CurrentDataForCalculation
	|";
	ListOfRequests.Add(QueryText);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	If DataChunkSize <> 0 Then
		SearchString = "SELECT TOP 50 DISTINCT"; // @query-part
		ReplacementString = "SELECT TOP %1 DISTINCT"; // @query-part
		QueryText = StrReplace(QueryText, SearchString, StrTemplate(ReplacementString, Format(DataChunkSize, "NG=0;")));
	Else
		SearchString = "SELECT TOP 50 DISTINCT"; // @query-part
		ReplacementString = "SELECT DISTINCT"; // @query-part
		QueryText = StrReplace(QueryText, SearchString, ReplacementString);
	EndIf;
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", EndOfMonth(BeginOfPeriod));
	Query.SetParameter("BusinessTransactions", BusinessTransactions);
	Query.SetParameter("FilterByBusinessTransaction", BusinessTransactions.Count() <> 0);
	
	Result = Query.Execute();
	Selection = Result.Select();
	Selection.Next();

	TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TTUsed);

	Return Selection.Count;
	
EndFunction

// Generates a calculation data table, which is used to generate Registered Records.
// Objects are added to the table:
//  - specified in the same document;
//  - components and FA-owners.
// 
// Parameters:
//  TempTablesManager  - TempTablesManager - there should be a table in the proportions given by the account
Procedure CreateTTTableOfDataToBeCalculated(TempTablesManager) Export
	
	TTUsed = TMCommonUse.ListOfTemporaryTables(TempTablesManager);
	TTUsed.Add("TTDataToBeCalculated");

	QueryText =
	"SELECT DISTINCT
	|	DataForCalculation.Ref AS Ref,
	|	DataForCalculation.Date AS Date,
	|	DataForCalculation.Organization AS Organization,
	|	CAST(DataForCalculation.Organization AS Catalog.Companies).ParentCompany AS ParentCompany,
	|	DataForCalculation.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DataForCalculation.RecordInManAccounting AS RecordInManAccounting,
	|	DataForCalculation.AccountingObject AS AccountingObject,
	|	DataForCalculation.Priority AS Priority
	|
	|INTO TTDataToBeCalculated
	|
	|FROM
	|	(SELECT
	|		TTPortionOfDataToBeCalculated.Ref AS Ref,
	|		TTPortionOfDataToBeCalculated.Date AS Date,
	|		TTPortionOfDataToBeCalculated.Organization AS Organization,
	|		TTPortionOfDataToBeCalculated.RecordInLocalAccounting AS RecordInLocalAccounting,
	|		TTPortionOfDataToBeCalculated.RecordInManAccounting AS RecordInManAccounting,
	|		TTPortionOfDataToBeCalculated.AccountingObject AS AccountingObject,
	|		TTPortionOfDataToBeCalculated.Priority AS Priority
	|	FROM
	|		TTPortionOfDataToBeCalculated AS TTPortionOfDataToBeCalculated
	|
	|	UNION ALL
	|
		// Adding all the FA of a single document, because the task can only be on one of them
	|	SELECT
	|		TTPortionOfDataToBeCalculated.Ref AS Ref,
	|		TTPortionOfDataToBeCalculated.Date AS Date,
	|		TTPortionOfDataToBeCalculated.Organization AS Organization,
	|		TTPortionOfDataToBeCalculated.RecordInLocalAccounting AS RecordInLocalAccounting,
	|		TTPortionOfDataToBeCalculated.RecordInManAccounting AS RecordInManAccounting,
	|		DependentObjects.FixedAsset AS AccountingObject,
	|		TTPortionOfDataToBeCalculated.Priority AS Priority
	|	FROM
	|		TTPortionOfDataToBeCalculated AS TTPortionOfDataToBeCalculated
	|
	|			INNER JOIN InformationRegister.FixedAssetsDocuments AS DependentObjects
	|			ON DependentObjects.Ref = TTPortionOfDataToBeCalculated.Ref
	|				AND DependentObjects.FixedAsset <> TTPortionOfDataToBeCalculated.AccountingObject
	|				AND NOT DependentObjects.AdditionalRecord
	|
	|	UNION ALL
	|	
		// Adding all the IA of one document, because the task can only be on one of them
	|	SELECT
	|		TTPortionOfDataToBeCalculated.Ref AS Ref,
	|		TTPortionOfDataToBeCalculated.Date AS Date,
	|		TTPortionOfDataToBeCalculated.Organization AS Organization,
	|		TTPortionOfDataToBeCalculated.RecordInLocalAccounting AS RecordInLocalAccounting,
	|		TTPortionOfDataToBeCalculated.RecordInManAccounting AS RecordInManAccounting,
	|		DependentObjects.IntangibleAsset AS AccountingObject,
	|		TTPortionOfDataToBeCalculated.Priority AS Priority
	|	FROM
	|		TTPortionOfDataToBeCalculated AS TTPortionOfDataToBeCalculated
	|
	|			INNER JOIN InformationRegister.IntangibleAssetsDocuments AS DependentObjects
	|			ON DependentObjects.Ref = TTPortionOfDataToBeCalculated.Ref
	|				AND DependentObjects.IntangibleAsset <> TTPortionOfDataToBeCalculated.AccountingObject
	|				AND NOT DependentObjects.AdditionalRecord
	|
	|	UNION ALL
	|	
		// Adding nodes/components, because a job can only be an owner
	|	SELECT
	|		TTPortionOfDataToBeCalculated.Ref AS Ref,
	|		TTPortionOfDataToBeCalculated.Date AS Date,
	|		TTPortionOfDataToBeCalculated.Organization AS Organization,
	|		TTPortionOfDataToBeCalculated.RecordInLocalAccounting AS RecordInLocalAccounting,
	|		TTPortionOfDataToBeCalculated.RecordInManAccounting AS RecordInManAccounting,
	|		SubAssetsComponentsOfDepreciation.SubAssetComponent AS AccountingObject,
	|		TTPortionOfDataToBeCalculated.Priority AS Priority
	|	FROM
	|		TTPortionOfDataToBeCalculated AS TTPortionOfDataToBeCalculated
	|
	|			INNER JOIN InformationRegister.SubAssetsComponentsOfDepreciation AS SubAssetsComponentsOfDepreciation
	|			ON SubAssetsComponentsOfDepreciation.FixedAsset = TTPortionOfDataToBeCalculated.AccountingObject
	|				AND SubAssetsComponentsOfDepreciation.Active
	|
	|	UNION ALL
	|	
		// Adding owners, because the task can only be on nodes/components
	|	SELECT
	|		TTPortionOfDataToBeCalculated.Ref AS Ref,
	|		TTPortionOfDataToBeCalculated.Date AS Date,
	|		TTPortionOfDataToBeCalculated.Organization AS Organization,
	|		TTPortionOfDataToBeCalculated.RecordInLocalAccounting AS RecordInLocalAccounting,
	|		TTPortionOfDataToBeCalculated.RecordInManAccounting AS RecordInManAccounting,
	|		SubAssetsComponentsOfDepreciation.FixedAsset AS AccountingObject,
	|		TTPortionOfDataToBeCalculated.Priority AS Priority
	|	FROM
	|		TTPortionOfDataToBeCalculated AS TTPortionOfDataToBeCalculated
	|
	|			INNER JOIN InformationRegister.SubAssetsComponentsOfDepreciation AS SubAssetsComponentsOfDepreciation
	|			ON SubAssetsComponentsOfDepreciation.SubAssetComponent = TTPortionOfDataToBeCalculated.AccountingObject
	|				AND SubAssetsComponentsOfDepreciation.FixedAsset <> VALUE(Catalog.Assets.EmptyRef)
	|				AND SubAssetsComponentsOfDepreciation.Active
	|
	|	) AS DataForCalculation
	|
	|INDEX BY
	|	Organization,
	|	AccountingObject
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	
	Query.Execute();
	
	TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TTUsed);
	
EndProcedure

// The amount of data to calculate.
// 
// Parameters:
//  TempTablesManager - TempTablesManager - temporary table Manager
//  TableName - String - table name
// 
// Returns:
//  Number - Number Of Data To Be Calculated
Function NumberOfDataToBeCalculated(TempTablesManager, TableName = "") Export
	
	QueryText =
	"SELECT
	|	ISNULL(COUNT(DISTINCT TTDataToBeCalculated.Ref), 0) AS DocumentsCount
	|FROM
	|	TTDataToBeCalculated AS TTDataToBeCalculated";
	
	If TableName <> "" Then
		QueryText = StrReplace(QueryText, "TTDataToBeCalculated", TableName);
	EndIf;
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Selection = Query.Execute().Select();
	
	DocumentsCount = 0;
	If Selection.Next() Then
		DocumentsCount = Selection.DocumentsCount;
	EndIf;
	
	Return DocumentsCount;
	
EndFunction

// Forms a queue of objects for multithreaded execution of operation.
// Objects will always have one queue number if:
//  - objects are selected in one document
//  - objects are components of the same owner.
// 
// Parameters:
//  TempTablesManager - TempTablesManager - It must contain tables of assignments to the account, and lists of documents.
//  MaximumQueueNumber - Number - If specified, the objects will be distributed so that the number of queues does not exceed the maximum.
//  									If not specified, the objects will not be allocated.
// 
// Returns:
//  ValueTable -  Object Queue:
//  	* AccountingObject - CatalogRef.Assets, CatalogRef.IntangibleAssets -
//  	* QueueNumber - Number
//
Function ObjectQueue(TempTablesManager, MaximumQueueNumber = 0) Export
	
	TTUsed = TMCommonUse.ListOfTemporaryTables(TempTablesManager);

	QueryText =
	"SELECT
	|	CurrentFacilities.Ref AS Ref,
	|	CurrentFacilities.FixedAsset AS AccountingObject,
	|	CurrentFacilities.RecNo AS RecNo
	|
	|INTO TTAllObjects
	|
	|FROM
	|	InformationRegister.FixedAssetsDocuments AS CurrentFacilities
	|
	|WHERE
	|	CurrentFacilities.Ref IN
	|			(SELECT
	|				TTListOfDocuments.Ref
	|			FROM
	|				TTListOfDocuments AS TTListOfDocuments)
	|
	|UNION ALL
	|
	|SELECT
	|	CurrentFacilities.Ref AS Ref,
	|	CurrentFacilities.IntangibleAsset AS AccountingObject,
	|	CurrentFacilities.RecNo AS RecNo
	|
	|FROM
	|	InformationRegister.IntangibleAssetsDocuments AS CurrentFacilities
	|
	|WHERE
	|	CurrentFacilities.Ref IN
	|			(SELECT
	|				TTListOfDocuments.Ref
	|			FROM
	|				TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref,
	|	RecNo,
	|	AccountingObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DependentObjects.AccountingObject AS AccountingObject,
	|	DependentObjects.DependentObject AS DependentObject
	|
	|INTO TTDependenceOfObjects
	|
	|FROM
		// Linking objects in one document
	|	(SELECT
	|		CurrentFacilities.AccountingObject AS AccountingObject,
	|		ISNULL(DependentObjects.AccountingObject, UNDEFINED) AS DependentObject
	|
	|	FROM
	|		TTAllObjects AS CurrentFacilities
	|
	|			INNER JOIN TTAllObjects AS DependentObjects
	|			ON DependentObjects.Ref = CurrentFacilities.Ref
	|				AND DependentObjects.AccountingObject <> CurrentFacilities.AccountingObject
	|				AND DependentObjects.RecNo <> 0
	|
	|	WHERE
	|		CurrentFacilities.RecNo = 0
	|
	|	UNION ALL
	|
		// Component communication with the FA-owner
	|	SELECT
	|		SubAssetsComponentsOfDepreciation.SubAssetComponent AS AccountingObject,
	|		SubAssetsComponentsOfDepreciation.FixedAsset AS DependentObject
	|
	|	FROM
	|		InformationRegister.SubAssetsComponentsOfDepreciation AS SubAssetsComponentsOfDepreciation
	|
	|	WHERE
	|		SubAssetsComponentsOfDepreciation.SubAssetComponent IN (
	|			SELECT
	|				JobsForCalculating.AccountingObject
	|			FROM
	|				JobsForCalculating AS JobsForCalculating)
	|
	|		AND SubAssetsComponentsOfDepreciation.FixedAsset IN (
	|			SELECT
	|				JobsForCalculating.AccountingObject
	|			FROM
	|				JobsForCalculating AS JobsForCalculating)
	|
	|		AND SubAssetsComponentsOfDepreciation.FixedAsset <> VALUE(Catalog.Assets.EmptyRef)
	|
	|	UNION ALL
	|
		// The FA-owner's relationship with the component 
	|	SELECT
	|		SubAssetsComponentsOfDepreciation.FixedAsset AS AccountingObject,
	|		SubAssetsComponentsOfDepreciation.SubAssetComponent AS DependentObject
	|
	|	FROM
	|		InformationRegister.SubAssetsComponentsOfDepreciation AS SubAssetsComponentsOfDepreciation
	|
	|	WHERE
	|		SubAssetsComponentsOfDepreciation.SubAssetComponent IN (
	|			SELECT
	|				JobsForCalculating.AccountingObject
	|			FROM
	|				JobsForCalculating AS JobsForCalculating)
	|
	|		AND SubAssetsComponentsOfDepreciation.FixedAsset IN (
	|			SELECT
	|				JobsForCalculating.AccountingObject
	|			FROM
	|				JobsForCalculating AS JobsForCalculating)
	|
	|		AND SubAssetsComponentsOfDepreciation.FixedAsset <> VALUE(Catalog.Assets.EmptyRef)
	|
	|	UNION ALL
	|
		// FA communication through the asset under construction 
	|	SELECT
	|		CurrentFacilities.FixedAsset AS AccountingObject,
	|		CurrentFacilities.ExpensesCapitalizationDimension AS DependentObject
	|
	|	FROM
	|		AccumulationRegister.FACost AS CurrentFacilities
	|
	|	WHERE
	|		CurrentFacilities.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND CurrentFacilities.DimensionKindExpenseCapitalization = VALUE(Enum.KindsOfExpenseCapitalizationDimension.ConstructionObject)
	|		AND CurrentFacilities.ExpensesCapitalizationDimension <> UNDEFINED
	|		AND CurrentFacilities.Active
	|
	|		AND CurrentFacilities.Recorder IN (
	|			SELECT
	|				TTListOfDocuments.Ref
	|			FROM
	|				TTListOfDocuments AS TTListOfDocuments)
	|
	|	) AS DependentObjects
	|
	|INDEX BY
	|	AccountingObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	JobsForCalculating.AccountingObject AS AccountingObject,
	|	ISNULL(TTDependenceOfObjects.DependentObject, UNDEFINED) AS DependentObject
	|
	|FROM
	|	JobsForCalculating AS JobsForCalculating
	|
	|		INNER JOIN TTDependenceOfObjects AS TTDependenceOfObjects
	|		ON TTDependenceOfObjects.AccountingObject = JobsForCalculating.AccountingObject
	|
	|GROUP BY
	|	JobsForCalculating.AccountingObject,
	|	ISNULL(TTDependenceOfObjects.DependentObject, UNDEFINED)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(JobsForCalculating.Month) AS Month,
	|	JobsForCalculating.AccountingObject AS AccountingObject,
	|	FALSE Processed
	|
	|FROM
	|	JobsForCalculating AS JobsForCalculating
	|
	|GROUP BY
	|	JobsForCalculating.AccountingObject
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	
	QueryResult = Query.ExecuteBatch();
	
	DependencyTable = QueryResult[QueryResult.UBound() - 1].Unload();
	DependencyTable.Indexes.Add("AccountingObject,DependentObject");

	ObjectsTable = QueryResult[QueryResult.UBound()].Unload();
	ObjectsTable.Indexes.Add("Processed");

	TypesOfAccountingObjects_ = New Array;
	TypesOfAccountingObjects_.Add(Type("CatalogRef.Assets"));
	TypesOfAccountingObjects_.Add(Type("CatalogRef.IntangibleAssets"));
	TypesOfAccountingObjects_.Add(Type("CatalogRef.ConstructionObjects"));
	
	ObjectQueue = New ValueTable();
	ObjectQueue.Columns.Add("AccountingObject", New TypeDescription(TypesOfAccountingObjects_));
	ObjectQueue.Columns.Add("QueueNumber", Common.TypeDescriptionNumber(31,, AllowedSign.Nonnegative));
	
	// The algorithm:
	// 1. Mark the Cur object as processed
	// 2. Add the Cur object to the list of dependent objects
	// 3. We go through the list of dependent objects
	//   3.1. Getting a dependent object from the list
	//   3.2. Removing the dependent object from the list
	//   3.3. We sort through all unprocessed objects:
	//   3.3.1. If an unprocessed object is associated with a dependent object, then
	//     3.3.1.1. Marking this object as processed
	//     3.3.1.2. Adding an object to the queue and to the list of dependent objects
	//   3.3.2. Otherwise we do nothing

	CurrentQueueNumber = 1;
	For Each CurrentObject In ObjectsTable Do
		
		If CurrentObject.Processed Then
			Continue;
		EndIf;
		
		CurrentObject.Processed = True;

		NewQueueObject = ObjectQueue.Add();
		NewQueueObject.Month = CurrentObject.Month;
		NewQueueObject.AccountingObject = CurrentObject.AccountingObject;
		NewQueueObject.QueueNumber = CurrentQueueNumber;
		
		DependentObjects = New Array;
		DependentObjects.Add(CurrentObject.AccountingObject);
		
		// 3. We go through the list of dependent objects
		While DependentObjects.Count() <> 0 Do
			
			DependentObject = DependentObjects[0];
			DependentObjects.Delete(0);
			
			// 3.3. We sort through all unprocessed objects
			TheStructureOfTheSearch = New Structure("Processed", False);
			ListOfObjectsThatWereNotProcessed = ObjectsTable.FindRows(TheStructureOfTheSearch);
			
			If ListOfObjectsThatWereNotProcessed.Count() = 0 Then
				DependentObjects.Clear();
				Break;
			EndIf;
			
			For Each UnprocessedObject In ListOfObjectsThatWereNotProcessed Do
				
				TheStructureOfTheSearch = New Structure("AccountingObject, DependentObject", UnprocessedObject.AccountingObject, DependentObject);
				ListOfObjects = DependencyTable.FindRows(TheStructureOfTheSearch);
				If ListOfObjects.Count() = 0 Then
					TheStructureOfTheSearch = New Structure("AccountingObject, DependentObject", DependentObject, UnprocessedObject.AccountingObject);
					ListOfObjects = DependencyTable.FindRows(TheStructureOfTheSearch);
				EndIf;
				
				// 3.3.1. If the unprocessed object is associated with a dependent object
				If ListOfObjects.Count() <> 0 Then
					
					UnprocessedObject.Processed = True;
					
					NewQueueObject = ObjectQueue.Add();
					NewQueueObject.AccountingObject = UnprocessedObject.AccountingObject;
					NewQueueObject.QueueNumber = CurrentQueueNumber;
					
					DependentObjects.Add(UnprocessedObject.AccountingObject);

				EndIf;
				
			EndDo;

		EndDo;
		
		CurrentQueueNumber = CurrentQueueNumber + 1;
		If CurrentQueueNumber > MaximumQueueNumber
			And MaximumQueueNumber <> 0 Then
			CurrentQueueNumber = 1;
		EndIf;
		
	EndDo;
	
	If MaximumQueueNumber <> 0 Then
		ObjectQueue.GroupBy("AccountingObject,QueueNumber");
	EndIf;
	
	ObjectQueue.Sort("QueueNumber");

	TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TTUsed);

	Return ObjectQueue;
	
EndFunction

// Forms a queue of objects for multithreaded execution of operations using the mechanism of the Linear Alignment System Calculation platform.
// Objects will always have one queue number if:
//  - objects are selected in one document
//  - objects are components of the same owner.
// 
// Parameters:
//  TempTablesManager - TempTablesManager - It must contain tables of assignments to the account, and lists of documents.
//  MaximumQueueNumber - Number - If specified, the objects will be distributed so that the number of queues does not exceed the maximum.
//  									If not specified, the objects will not be allocated.
// 
// Returns:
//  ValueTable -  Object Queue:
//  	* AccountingObject - CatalogRef.Assets, CatalogRef.IntangibleAssets - Accounting object
//  	* QueueNumber - Number - queue number
//
Function QueueOfSLEObjects(TempTablesManager, MaximumQueueNumber = 0) Export
	
	TTUsed = TMCommonUse.ListOfTemporaryTables(TempTablesManager);

	QueryText =
	"SELECT
	|	CurrentFacilities.Ref AS Ref,
	|	CurrentFacilities.FixedAsset AS AccountingObject,
	|	CurrentFacilities.RecNo AS RecNo
	|
	|INTO Queue_AllDocumentObjects
	|
	|FROM
	|	InformationRegister.FixedAssetsDocuments AS CurrentFacilities
	|
	|WHERE
	|	CurrentFacilities.Ref IN
	|			(SELECT
	|				TTListOfDocuments.Ref
	|			FROM
	|				TTListOfDocuments AS TTListOfDocuments)
	|
	|UNION ALL
	|
	|SELECT
	|	CurrentFacilities.Ref AS Ref,
	|	CurrentFacilities.IntangibleAsset AS AccountingObject,
	|	CurrentFacilities.RecNo AS RecNo
	|
	|FROM
	|	InformationRegister.IntangibleAssetsDocuments AS CurrentFacilities
	|
	|WHERE
	|	CurrentFacilities.Ref IN
	|			(SELECT
	|				TTListOfDocuments.Ref
	|			FROM
	|				TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref,
	|	RecNo,
	|	AccountingObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DependentObjects.AccountingObject AS AccountingObject,
	|	DependentObjects.DependentObject AS DependentObject
	|
	|INTO Queue_Dependency
	|
	|FROM
		// Linking objects in one document
	|	(SELECT
	|		CurrentFacilities.AccountingObject AS AccountingObject,
	|		ISNULL(DependentObjects.AccountingObject, CurrentFacilities.AccountingObject) AS DependentObject
	|
	|	FROM
	|		Queue_AllDocumentObjects AS CurrentFacilities
	|
	|			LEFT JOIN Queue_AllDocumentObjects AS DependentObjects
	|			ON DependentObjects.Ref = CurrentFacilities.Ref
	|				AND DependentObjects.AccountingObject <> CurrentFacilities.AccountingObject
	|				AND DependentObjects.RecNo <> 0
	|
	|	WHERE
	|		CurrentFacilities.RecNo = 0
	|
	|	UNION ALL
	|
		// Component communication with the FA-owner
	|	SELECT
	|		SubAssetsComponentsOfDepreciation.SubAssetComponent AS AccountingObject,
	|		SubAssetsComponentsOfDepreciation.FixedAsset AS DependentObject
	|
	|	FROM
	|		InformationRegister.SubAssetsComponentsOfDepreciation AS SubAssetsComponentsOfDepreciation
	|
	|	WHERE
	|		SubAssetsComponentsOfDepreciation.SubAssetComponent IN (
	|			SELECT
	|				AllObjects.AccountingObject
	|			FROM
	|				Queue_AllDocumentObjects AS AllObjects)
	|
	|		AND SubAssetsComponentsOfDepreciation.FixedAsset IN (
	|			SELECT
	|				AllObjects.AccountingObject
	|			FROM
	|				Queue_AllDocumentObjects AS AllObjects)
	|
	|		AND SubAssetsComponentsOfDepreciation.FixedAsset <> VALUE(Catalog.Assets.EmptyRef)
	|
	|	UNION ALL
	|
		// The FA-owner's relationship with the component 
	|	SELECT
	|		SubAssetsComponentsOfDepreciation.FixedAsset AS AccountingObject,
	|		SubAssetsComponentsOfDepreciation.SubAssetComponent AS DependentObject
	|
	|	FROM
	|		InformationRegister.SubAssetsComponentsOfDepreciation AS SubAssetsComponentsOfDepreciation
	|
	|	WHERE
	|		SubAssetsComponentsOfDepreciation.SubAssetComponent IN (
	|			SELECT
	|				AllObjects.AccountingObject
	|			FROM
	|				Queue_AllDocumentObjects AS AllObjects)
	|
	|		AND SubAssetsComponentsOfDepreciation.FixedAsset IN (
	|			SELECT
	|				AllObjects.AccountingObject
	|			FROM
	|				Queue_AllDocumentObjects AS AllObjects)
	|
	|		AND SubAssetsComponentsOfDepreciation.FixedAsset <> VALUE(Catalog.Assets.EmptyRef)
	|
	|	UNION ALL
	|
		// FA communication through the asset under construction 
	|	SELECT
	|		CurrentFacilities.FixedAsset AS AccountingObject,
	|		CurrentFacilities.ExpensesCapitalizationDimension AS DependentObject
	|
	|	FROM
	|		AccumulationRegister.FACost AS CurrentFacilities
	|
	|	WHERE
	|		CurrentFacilities.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND CurrentFacilities.DimensionKindExpenseCapitalization = VALUE(Enum.KindsOfExpenseCapitalizationDimension.ConstructionObject)
	|		AND CurrentFacilities.ExpensesCapitalizationDimension <> UNDEFINED
	|		AND CurrentFacilities.Active
	|
	|		AND CurrentFacilities.Recorder IN (
	|			SELECT
	|				AllObjects.Ref
	|			FROM
	|				Queue_AllDocumentObjects AS AllObjects)
	|
	|	) AS DependentObjects
	|
	|INDEX BY
	|	AccountingObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ListOfObjects.AccountingObject AS AccountingObject,
	|	RECORDAUTONUMBER() ObjectNumber
	|
	|INTO Queue_ObjectNumbers
	|
	|FROM
	|	(SELECT
	|		ListOfObjects.AccountingObject AS AccountingObject
	|	FROM
	|		(SELECT
	|			Dependence.AccountingObject AS AccountingObject
	|		FROM
	|			Queue_Dependency AS Dependence
	|
	|		UNION ALL
	|
	|		SELECT
	|			Dependence.DependentObject AS AccountingObject
	|		FROM
	|			Queue_Dependency AS Dependence
	|
	|		UNION ALL
	|
	|		SELECT
	|			JobsForCalculating.AccountingObject AS AccountingObject
	|		FROM
	|			JobsForCalculating AS JobsForCalculating
	|
	|		) AS ListOfObjects
	|
	|	GROUP BY
	|		ListOfObjects.AccountingObject
	|
	|	) AS ListOfObjects
	|
	|INDEX BY
	|	AccountingObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ObjectRelationships.ObjectNumber AS ObjectNumber,
	|	ObjectRelationships.DependentObjectNumber AS DependentObjectNumber,
	|	1 AS ZoomRatio
	|
	|FROM
	|	(SELECT
	|		ListOfObjects.ObjectNumber AS ObjectNumber,
	|		ISNULL(ListOfDependencyObjects.ObjectNumber, ListOfObjects.ObjectNumber) AS DependentObjectNumber
	|
	|FROM
	|		Queue_ObjectNumbers AS ListOfObjects
	|
	|			LEFT JOIN Queue_Dependency AS Dependence
	|			ON Dependence.AccountingObject = ListOfObjects.AccountingObject
	|
	|			LEFT JOIN Queue_ObjectNumbers AS ListOfDependencyObjects
	|			ON ListOfDependencyObjects.AccountingObject = Dependence.DependentObject
	|
	|	UNION ALL
	|
	|	SELECT
	|		ListOfObjects.ObjectNumber AS ObjectNumber,
	|		ISNULL(ListOfDependencyObjects.ObjectNumber, ListOfObjects.ObjectNumber) AS DependentObjectNumber
	|
	|	FROM
	|		Queue_ObjectNumbers AS ListOfObjects
	|
	|			LEFT JOIN Queue_Dependency AS Dependence
	|			ON Dependence.DependentObject = ListOfObjects.AccountingObject
	|
	|			LEFT JOIN Queue_ObjectNumbers AS ListOfDependencyObjects
	|			ON ListOfDependencyObjects.AccountingObject = Dependence.AccountingObject
	|
	|	) AS ObjectRelationships
	|
	|GROUP BY
	|	ObjectRelationships.ObjectNumber,
	|	ObjectRelationships.DependentObjectNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ListOfObjects.AccountingObject AS AccountingObject,
	|	ListOfObjects.ObjectNumber AS ObjectNumber
	|FROM
	|	Queue_ObjectNumbers AS ListOfObjects
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	
	QueryResult = Query.ExecuteBatch();
	
	DependencyTable = QueryResult[QueryResult.UBound() - 1].Unload();

	ObjectsTable = QueryResult[QueryResult.UBound()].Unload();
	ObjectsTable.Indexes.Add("ObjectNumber");

	SLECalculation = New SystemOfLinearEquationsCalculation;
	SLECalculation.RelationDataSource = DependencyTable;
	SLECalculation.EquationsInRelationsColumn = "ObjectNumber";
	SLECalculation.VariablesInRelationsColumn = "DependentObjectNumber";
	SLEDescription = SLECalculation.SystemsDescription.Add();
	SLEDescription.FactorsInRelationsColumn = "ZoomRatio";
	
	ConnectivityOfObjects = SLECalculation.GetConnectedComponents(ConnectedComponentsOfSystemOfLinearEquationsCalculationGettingMethod.WeaklyConnectedComponents);
	ConnectivityOfObjects.Sort("ComponentNumber");
	
	ObjectQueue = New ValueTable();
	ObjectQueue.Columns.Add("AccountingObject", New TypeDescription(ObjectsTable.Columns.AccountingObject.ValueType));
	ObjectQueue.Columns.Add("QueueNumber", Common.TypeDescriptionNumber(31,, AllowedSign.Nonnegative));
	
	CurrentQueueNumber = 1;
	CurCurrentComponentNumber = 0;
	For Each Selection In ConnectivityOfObjects Do

		If CurCurrentComponentNumber <> Selection.ComponentNumber Then
			
			CurrentQueueNumber = CurrentQueueNumber + 1;
			If CurrentQueueNumber > MaximumQueueNumber
				And MaximumQueueNumber <> 0 Then
				CurrentQueueNumber = 1;
			EndIf;
			
		EndIf;
		
		ObjectData = ObjectsTable.Find(Selection.NodeNumber, "ObjectNumber");

		NewQueueObject = ObjectQueue.Add();
		NewQueueObject.AccountingObject = ObjectData.AccountingObject;
		NewQueueObject.QueueNumber = CurrentQueueNumber;

		CurCurrentComponentNumber = Selection.ComponentNumber;

	EndDo;
	
	TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TTUsed);

	Return ObjectQueue;
	
EndFunction

// Generates a list of tasks from the object queue.
// 
// Parameters:
//  ObjectQueue - See ObjectQueue
//  DataChunkSize - Number - The maximum number of objects in the job (in fact, there may be more objects if they have the same queue number).
//  CalculationProcedure_ - String - The name of the procedure that is being performed for processing.
//  TemplateForTaskParameters - Structure - Template for task parameters.
//  TemplateForNameOfBackgroundTask - String - Template for the name of the background task.
// 
// Returns:
//  See InitiateTaskQueue 
Function CreateTasksFromQueueOfObjects(ObjectQueue, DataChunkSize, CalculationProcedure_, TemplateForTaskParameters, TemplateForNameOfBackgroundTask) Export

	TaskQueue = InitiateTaskQueue();

	ObjectCount = ObjectQueue.Count();
	
	If ObjectCount = 0 Then
		Return TaskQueue;
	EndIf;
	
	TaskData_ = Undefined;
	CurrentQueueNumber = Undefined;
	CurNumberOfObjects = 0;
	FirstNumberOfObject = 0;
	CurNumberOfObject = 0;
	 
	For Each Selection In ObjectQueue Do
		
		CurNumberOfObjects = CurNumberOfObjects + 1;
		CurNumberOfObject = CurNumberOfObject + 1;
		
		If TaskData_ = Undefined 
			Or CurrentQueueNumber <> Selection.QueueNumber
				And CurNumberOfObjects > DataChunkSize Then
			
			// Adding a new task if the number of objects is exceeded and the queue number differs
			
			If TaskData_ <> Undefined Then
				
				TaskData_.BackgroundJobDescription = 
					StrTemplate(
						TemplateForNameOfBackgroundTask, 
						Format(FirstNumberOfObject, "NG=0;"), 
						Format(CurNumberOfObject - 1, "NG=0;"),
						Format(ObjectCount, "NG=0;")); 

			EndIf;
			
			TaskData_ = TaskQueue.Add();
			TaskData_.CalculationProcedure_ = CalculationProcedure_;
			TaskData_.JobParameters = Common.CopyRecursive(TemplateForTaskParameters);
			
			FirstNumberOfObject = CurNumberOfObject;
			CurrentQueueNumber = Selection.QueueNumber;
			CurNumberOfObjects = 1;
			
		EndIf;
		
		JobParameters = TaskData_.JobParameters; // see the Execution ParameterReferences
		
		ObjectParameters = JobParameters.ListOfObjects.Add();
		ObjectParameters.AccountingObject = Selection.AccountingObject;
		
	EndDo;
	
	If TaskData_ <> Undefined Then
		
		TaskData_.BackgroundJobDescription = 
			StrTemplate(
				TemplateForNameOfBackgroundTask, 
				Format(FirstNumberOfObject, "NG=0;"), 
				Format(CurNumberOfObject, "NG=0;"),
				Format(ObjectCount, "NG=0;")); 

	EndIf;

	Return TaskQueue;
	
EndFunction

// Checks the availability of tasks in the information register.
//
// Parameters:
//  HandlerParameters - Structure - Handler Parameters
//	TaskRegisterName - String - Name of the register of information with tasks
//	
// Returns:
//	Boolean - indicates whether there are register entries.
//
Function CheckAvailabilityOfTasksByEndOfMonth(HandlerParameters, TaskRegisterName) Export
	
	DataOfTasks = TaskDataByEndOfMonth(
		HandlerParameters.CalculationParameters.EndOfPeriod, 
		HandlerParameters.CalculationParameters.CompanyArray,
		TaskRegisterName);
	
	If DataOfTasks.ObjectCount = 0
		Or DataOfTasks.SettlementStartDate = '00010101' Then
		Return False;
	EndIf;
	
	HandlerParameters.Data_Stage.SettlementStartDate = DataOfTasks.SettlementStartDate;

	If Upper(TaskRegisterName) = Upper(Metadata.InformationRegisters.JobsForCalculatingFixedAssetDepreciation.Name)
		Or Upper(TaskRegisterName) = Upper(Metadata.InformationRegisters.JobsForCalculatingIntangibleAssetAmortization.Name) Then
	
		StateTemplate = ?(DataOfTasks.ObjectCount = 1,
			NStr("vi = 'Cần thực hiện giao dịch bắt đầu từ kỳ %1 theo gói %2';
				|ru = 'Требуется выполнение операции начиная с периода %1 по %2 пакету';
				|en = 'Perform month-end closing starting from %1 for the %2 package'; fa = 'Perform month-end closing starting from %1 for the %2 package';
				|it = 'Требуется выполнение операции начиная с периода %1 по %2 пакету';
				|pl = 'Perform month-end closing starting from %1 for the %2 package';
				|tr = '%2 pakete göre %1 döneminden bir işlem gerçekleştirilmesi gerekmektedir'", Common.DefaultLanguageCode()),
			NStr("vi = 'Cần thực hiện giao dịch bắt đầu từ kỳ %1 theo các gói %2';
				|ru = 'Требуется выполнение операции начиная с периода %1 по %2 пакетам';
				|en = 'Perform month-end closing starting from %1 for the %2 packages'; fa = 'Perform month-end closing starting from %1 for the %2 packages';
				|it = 'Требуется выполнение операции начиная с периода %1 по %2 пакетам';
				|pl = 'Perform month-end closing starting from %1 for the %2 packages';
				|tr = '%2 paketlerine göre %1 döneminden bir işlem gerçekleştirilmesi gerekmektedir'", Common.DefaultLanguageCode()));
							
	Else
		
		StateTemplate = ?(DataOfTasks.ObjectCount = 1,
			NStr("vi = 'Cần thực hiện giao dịch bắt đầu từ kỳ %1 theo đối tượng %2';
				|ru = 'Требуется выполнение операции начиная с периода %1 по %2 объекту';
				|en = 'Perform month-end closing starting from %1 for the %2 object'; fa = 'Perform month-end closing starting from %1 for the %2 object';
				|it = 'Требуется выполнение операции начиная с периода %1 по %2 объекту';
				|pl = 'Perform month-end closing starting from %1 for the %2 object';
				|tr = '%2 nesnesine göre %1 döneminden bir işlem gerçekleştirilmesi gerekmektedir'", Common.DefaultLanguageCode()),
			NStr("vi = 'Cần thực hiện giao dịch bắt đầu từ kỳ %1 theo các đối tượng %2';
				|ru = 'Требуется выполнение операции начиная с периода %1 по %2 объектам';
				|en = 'Perform month-end closing starting from %1 for the %2 objects'; fa = 'Perform month-end closing starting from %1 for the %2 objects';
				|it = 'Требуется выполнение операции начиная с периода %1 по %2 объектам';
				|pl = 'Perform month-end closing starting from %1 for the %2 objects';
				|tr = '%2 nesnelerine göre %1 döneminden bir işlem gerçekleştirilmesi gerekmektedir'", Common.DefaultLanguageCode()));
			
	EndIf;
	
	MonthEndTransactionsServer.SetStateFailed(
		HandlerParameters,
		StringFunctionsClientServer.SubstituteParametersToString(
			StateTemplate,
			CostCalculationProtocol.PresentationOfCalculationPeriod(DataOfTasks.SettlementStartDate),
			Format(DataOfTasks.ObjectCount, "NG=3,0;")));
		
	Return True;
	
EndFunction

// Generates task data in the information register.
//
// Parameters:
//  Period - Date - month of calculation
//  CompaniesList - Array of CatalogRef.Companies - 
//	TaskRegisterName - String - Name of the register of information with tasks
//	
// Returns:
//	Structure - Contains:
//		* ObjectCount - Number -
//		* SettlementStartDate - Date -
//
Function TaskDataByEndOfMonth(Period, CompaniesList, TaskRegisterName) Export
	
	DataOfTasks = New Structure;
	DataOfTasks.Insert("ObjectCount", 0);
	DataOfTasks.Insert("SettlementStartDate", '00010101');
	
	QueryText =
	"SELECT DISTINCT
	|	Jobs.AccountingObject AS TasksObject,
	|	BEGINOFPERIOD(Jobs.Month, Month) AS Month
	|
	|INTO Jobs
	|
	|FROM
	|	InformationRegister.JobsForGeneratingFixedAssetRecords AS Jobs
	|
	|WHERE
	|	Jobs.Month <= &EndOfPeriod
	|	AND Jobs.Organization IN (&CompaniesList)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(COUNT(DISTINCT Jobs.TasksObject), 0) AS ObjectCount
	|FROM
	|	Jobs AS Jobs
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(MIN(Jobs.Month), UNDEFINED) AS Month
	|FROM
	|	Jobs AS Jobs
	|";
	
	QueryText = StrReplace(QueryText, "JobsForGeneratingFixedAssetRecords", TaskRegisterName);
	
	If Upper(TaskRegisterName) = Upper(Metadata.InformationRegisters.JobsForCalculatingFixedAssetDepreciation.Name)
		Or Upper(TaskRegisterName) = Upper(Metadata.InformationRegisters.JobsForCalculatingIntangibleAssetAmortization.Name) Then
			
		QueryText = StrReplace(QueryText, "Jobs.AccountingObject", "Jobs.PackageNumber");
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("EndOfPeriod", EndOfMonth(Period));
	Query.SetParameter("CompaniesList", CompaniesList);
	
	Result = Query.ExecuteBatch();
	
	Selection = Result[Result.UBound()].Select();
	Selection.Next();
	
	If Not ValueIsFilled(Selection.Month) Then
		Return DataOfTasks;
	EndIf;
	
	DataOfTasks.SettlementStartDate = Selection.Month;

	Selection = Result[Result.UBound()-1].Select();
	Selection.Next();
	
	DataOfTasks.ObjectCount = Selection.ObjectCount;
	
	Return DataOfTasks;
	
EndFunction

#EndRegion

#Region Other
 
// Empty ways to reflect expenses.
// 
// Returns:
//  Array of DocumentRef - Empty Ways To Reflect Expenses
Function EmptyWaysToReflectDepreciation() Export

	EmptyWaysToReflectDepreciation = New Array;
	EmptyWaysToReflectDepreciation.Add(Undefined);
	EmptyWaysToReflectDepreciation.Add(NULL);
	EmptyWaysToReflectDepreciation.Add(Documents.ChangeFixedAssetFinancialDetails2_4.EmptyRef());
	EmptyWaysToReflectDepreciation.Add(Documents.ChangeIntangibleAssetFinancialDetails2_4.EmptyRef());

	NonCurrentAssetsLocalization.ComplementEmptyWaysToReflectDepreciation(EmptyWaysToReflectDepreciation);
	
	Return EmptyWaysToReflectDepreciation;
	
EndFunction

Procedure AddNewEntriesToRegister(Recorder, RegisterName, NewRecords, SourceKind) Export

	RecordSet = AccumulationRegisters[RegisterName].CreateRecordSet();
	RecordSet.Filter.Recorder.Set(Recorder);
	RecordSet.Read();
	
	For Cnt = -RecordSet.Count() + 1 To 0 Do
		If RecordSet[-Cnt].SourceKind = SourceKind Then
			RecordSet.Delete(-Cnt);
		EndIf; 
	EndDo; 
	
	For Each SourceTableRow In NewRecords Do
		NewRecord = RecordSet.Add();
		FillPropertyValues(NewRecord, SourceTableRow);
		NewRecord.SourceKind = SourceKind;
	EndDo;
	
	RecordSet.Write();
	
EndProcedure

Function ReplaceQueryText(QueryText, RegisterName, NameOfSliceTable, RegisterParameters)
	
	QueryText = StrReplace(QueryText, "TT_RegisterName", RegisterName);
	QueryText = StrReplace(QueryText, "InformationRegister.InitialFixedAssetsInformation", "InformationRegister." + RegisterName);
	QueryText = StrReplace(QueryText, "VT_RegisterSlice", NameOfSliceTable);
		
	QueryText = StrReplace(QueryText, "&SelectingFields", RegisterParameters.SelectingFields);
	QueryText = StrReplace(QueryText, "&SamplingOfMeasurements", RegisterParameters.SamplingOfMeasurements);
	QueryText = StrReplace(QueryText, "&GroupingDimensions", RegisterParameters.GroupingDimensions);
	QueryText = StrReplace(QueryText, "&MeasurementsIndex", RegisterParameters.MeasurementsIndex);
	QueryText = StrReplace(QueryText, "&ConditionForJoiningMainTable", RegisterParameters.ConditionForJoiningMainTable);
	QueryText = StrReplace(QueryText, "&ConditionForJoiningRegisterTables", RegisterParameters.ConditionForJoiningRegisterTables);
	
	Return QueryText;
	
EndFunction

// VAT taxation.
// 
// Parameters:
//  Organization - CatalogRef.Companies - Organization
//  Date - Date - Date
// 
// Returns:
//  EnumRef.VATTaxationTypes - VAT taxation
Function VATTaxation(Organization, Date) Export
	
	SliceDate = ?(ValueIsFilled(Date), Date, CurrentSessionDate());
	
	VATTaxation = Enums.VATTaxationTypes.SaleIsSubjectToVAT;
	
	
	Return VATTaxation;
	
EndFunction

Function NameOfRegisterOfRecordSubjectToCorrections(RegisterName)
	
	Return RegisterName + "_RecordsSubjectToCorrections";
	
EndFunction

Function NameOfRegisterIsSliceOfLatestOnesTakingIntoAccountCorrections(RegisterName)
	
	Return RegisterName + "_CrossSectionOfLatterTakingIntoAccountCorrections";
	
EndFunction

// Detects changes in the document and saves them in the Additional Session property.
// Called in the document event before recording.
// 
// Parameters:
//  Object - DocumentObject - Document
//  WriteMode - DocumentWriteMode - Recording mode
//  AttributesNotToCheck - Structure, Undefined - unverified Bank details
//  UnverifiableTableParts - Structure, Undefined - Unverifiable Table Parts
// 
Procedure IdentifyDocumentChanges(Object, WriteMode, AttributesNotToCheck = Undefined, UnverifiableTableParts = Undefined) Export
	
	If ExchangePlans.MasterNode() <> Undefined
		Or Object.IsNew()
		Or WriteMode = DocumentWriteMode.Write
			And Not Object.Posted Then
		Return;
	EndIf;
	
	If AttributesNotToCheck = Undefined Then
		AttributesNotToCheck = New Structure;
	EndIf;
	
	If UnverifiableTableParts = Undefined Then
		UnverifiableTableParts = New Structure;
	EndIf;

	AttributesNotToCheck.Insert("DocumentInAnotherAccounting");
	AttributesNotToCheck.Insert("DocumentBasis");
	AttributesNotToCheck.Insert("GeneratedDocument");
	AttributesNotToCheck.Insert("FixedAssetsEvent");
	AttributesNotToCheck.Insert("EmployeeResponsible");
	AttributesNotToCheck.Insert("Comment");
	AttributesNotToCheck.Insert("RowID");

	UnverifiableTableParts.Insert("AdditionalAttributes");
		
	DocumentChanges = TMCommonUse.DocumentChanges(Object, AttributesNotToCheck, UnverifiableTableParts, True);
	
	Object.AdditionalProperties.Insert("DocumentChanges", DocumentChanges);
	
EndProcedure

// Generates tasks for the end of the month when conducting, if there are changes in the document.
// Tasks are generated using the new and old organization and date values.
// Before calling, you need to get the changes using the procedure to determine the change of the document.
// It is used for those documents that, during the execution, do not change the registers for which the tasks are generated.
// 
// Parameters:
//  Object - DocumentObject - Document
//  ListOfAccountingObjects - Array of CatalogRef.Assets, CatalogRef.IntangibleAssets - Accounting Objects
// 
Procedure GenerateTasksONChangingDocument(Object, ListOfAccountingObjects) Export
	
	DocumentChanges = Undefined;
	Object.AdditionalProperties.Property("DocumentChanges", DocumentChanges);		
	
	If DocumentChanges = Undefined
		Or Not DocumentChanges.Property("Attributes")
			And Not DocumentChanges.Property("TabularSections") Then
		Return; // No changes
	EndIf;
	
	MetadataOfDocument = Object.Metadata();
	TableName = MetadataOfDocument.Name + "Update";
	TempTablesManager = New TempTablesManager();
	
	QueryText =
	"SELECT
	|	&Ref AS Document,
	|	ListOfObjects.Ref AS NonCurrentAsset,
	|	&Organization AS Organization,
	|	&Date AS Period
	|
	|INTO TableName
	|
	|FROM
	|	Catalog.Assets AS ListOfObjects
	|
	|WHERE
	|	ListOfObjects.Ref IN (&ListOfAccountingObjects)
	|
	|UNION ALL
	|
	|SELECT
	|	&Ref AS Document,
	|	ListOfObjects.Ref AS NonCurrentAsset,
	|	&Organization AS Organization,
	|	&Date AS Period
	|
	|FROM
	|	Catalog.IntangibleAssets AS ListOfObjects
	|
	|WHERE
	|	ListOfObjects.Ref IN (&ListOfAccountingObjects)
	|
	|UNION ALL
	|
	|SELECT
	|	&Ref AS Document,
	|	ListOfObjects.Ref AS NonCurrentAsset,
	|
	|	CASE
	|		WHEN &Company_OldValue <> VALUE(Catalog.Companies.EmptyRef)
	|			THEN &Company_OldValue
	|		ELSE &Organization
	|	END AS Organization,
	|
	|	CASE
	|		WHEN &Date_OldValue <> DATETIME(1,1,1)
	|			THEN &Date_OldValue
	|		ELSE &Date
	|	END AS Period
	|
	|FROM
	|	Catalog.Assets AS ListOfObjects
	|
	|WHERE
	|	ListOfObjects.Ref IN (&ListOfAccountingObjects)
	|	AND (&Company_OldValue <> VALUE(Catalog.Companies.EmptyRef)
	|		OR &Date_OldValue <> DATETIME(1,1,1))
	|
	|UNION ALL
	|
	|SELECT
	|	&Ref AS Document,
	|	ListOfObjects.Ref AS NonCurrentAsset,
	|
	|	CASE
	|		WHEN &Company_OldValue <> VALUE(Catalog.Companies.EmptyRef)
	|			THEN &Company_OldValue
	|		ELSE &Organization
	|	END AS Organization,
	|
	|	CASE
	|		WHEN &Date_OldValue <> DATETIME(1,1,1)
	|			THEN &Date_OldValue
	|		ELSE &Date
	|	END AS Period
	|
	|FROM
	|	Catalog.IntangibleAssets AS ListOfObjects
	|
	|WHERE
	|	ListOfObjects.Ref IN (&ListOfAccountingObjects)
	|	AND (&Company_OldValue <> VALUE(Catalog.Companies.EmptyRef)
	|		OR &Date_OldValue <> DATETIME(1,1,1))
	|";
	
	QueryText = StrReplace(QueryText, "TableName", TableName);
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("ListOfAccountingObjects", ListOfAccountingObjects);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Date", Object.Date);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Date_OldValue", '00010101');
	Query.SetParameter("Company_OldValue", Catalogs.Companies.EmptyRef());
	
	If DocumentChanges.Property("Attributes") Then
		
		RowData = DocumentChanges.Attributes.Find("Date", "Name");
		If RowData <> Undefined Then
			Query.SetParameter("Date_OldValue", RowData.PreviousValue2);
		EndIf;
		
		RowData = DocumentChanges.Attributes.Find("Organization", "Name");
		If RowData <> Undefined Then
			Query.SetParameter("Company_OldValue", RowData.PreviousValue2);
		EndIf;

	EndIf;
	
	SetPrivilegedMode(True);
	Query.Execute();
	SetPrivilegedMode(False);
	
	TablesData = DocumentsPosting.OldStructureTableData(Object, TempTablesManager);
	TablesData.Insert(TableName, True);
	
	GenerateTaskRegisterEntries(Object, TablesData);
	
EndProcedure

#EndRegion

#EndRegion
