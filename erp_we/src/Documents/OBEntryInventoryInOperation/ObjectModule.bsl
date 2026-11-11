#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ItemDetailsParameters = 
		InventoryInOperationClientServer.ValuesOfPropertiesOfDependentDetails_InputOfRemainingInventoryItemsInOperation(ThisObject, AddlParameters());
	
	TMCommonUseClientServer.ClearUnusedProps(ThisObject, ItemDetailsParameters, "InventoryInOperation");
	
	InventoryInOperationServer.FillInAttributesByCategoryOfOperation(InventoryInOperation);
	
	Catalogs.LotsOfInventoryInOperation.FillInBatches(ThisObject, WriteMode);
	
	ProductsServer.ClearUnusedSeries(
		ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.OBEntryInventoryInOperation));
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "InventoryInOperation");

	OBEntryLocalization.OBEntryInventoryInOperationBeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	OBEntryLocalization.InputOfResiduesOfTMTSVOperationProcessing(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	OBEntryLocalization.InputOfResiduesTMTSVOperationProcessingOfRemovalOfWaste(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array();

	AddlParameters = AddlParameters();
	
	ItemDetailsParameters = 
		InventoryInOperationClientServer.ValuesOfPropertiesOfDependentDetails_InputOfRemainingInventoryItemsInOperation(ThisObject, AddlParameters);
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, AttributesNotToCheck);

	CheckingDocumentFilling(AddlParameters, AttributesNotToCheck, Cancel);
	CheckingFillingOfOtherSubsystems(AttributesNotToCheck, Cancel);
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
	OBEntryLocalization.EnteringResiduesOfTMTSVOperationProcessingFillingChecks(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	EmployeeResponsible = Users.CurrentUser();
	InitializeDocument(FillingData);
	
	If TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	EndIf;
	
	OBEntryLocalization.InputOfResiduesTMTSVOperationProcessingOfFilling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "InventoryInOperation");

	OBEntryLocalization.EnteringRemnantsOfTMTSVOperationWhenCopying(ThisObject, CopiedObject);
	
EndProcedure

Procedure OnWrite(Cancel)

	If DataExchange.Load Then
		Return
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	OBEntryLocalization.EnteringRemnantsOfTMTSVOperationDuringRecording(ThisObject, Cancel);

EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return
	EndIf;
	
	OBEntryLocalization.EnteringResiduesOfTMTSVOperationBeforeDisposal(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)

	If Not GetFunctionalOption("UseMultipleCompanies") Then
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("BusinessOperation") Then
			BusinessOperation = FillingData.BusinessOperation;
		EndIf;
		
		If FillingData.Property("Comment") Then
			Comment = FillingData.Comment;
		EndIf;
		
		If FillingData.Property("CopyingValue") Then
			OBEntryServer.FillInValuesForOldInputBalances(ThisObject, FillingData.CopyingValue);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

Procedure CheckingDocumentFilling(AddlParameters, AttributesNotToCheck, Cancel)
	
	If Not RecordInOperationalAccounting 
		And Not PostInFinancialAndTaxAccounting 
		And Not RecordInMA Then
			
		MessageText = NStr("vi = 'Giao dịch cần được phản ánh vào một trong các dạng kế toán';
							|ru = 'Операция должна отражаться в одном из учетов';
							|en = 'The operation must be recorded in one of accounting types'; fa = 'The operation must be recorded in one of accounting types';
							|it = 'L''operazione deve essere riportata in uno dei tipi della contabilità';
							|pl = 'Operacja powinna być odzwierciedlana w jednej z ewidencji';
							|tr = 'İşlemin hesaplardan birine yansıtılması gerekir'");
		Common.MessageToUser(MessageText,, "Object.RecordInOperationalAccounting",, Cancel);
	EndIf;
	
	InventoryInOperationServer.CheckTransferIntoOperation(ThisObject, AttributesNotToCheck, Cancel);
	
	CheckTMTSVOfOperation(AddlParameters, AttributesNotToCheck, Cancel);
	
EndProcedure

Procedure CheckingFillingOfOtherSubsystems(AttributesNotToCheck, Cancel)
	If Date < LocalAccntingClientServer.BeginningOfApplicationFSBU5_2019()
		And Date <> '000101010000' Then
		ChartsOfCharacteristicTypes.ExpenseItems.CheckAnalystCompletion(
			ThisObject, New Structure("InventoryInOperation"), AttributesNotToCheck, Cancel);
	EndIf;
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.TSName = "InventoryInOperation";
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, AttributesNotToCheck, Cancel, CheckParameters);
	
	ProductsServer.CheckSeriesCompletion(
		ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.OBEntryInventoryInOperation),
		Cancel,
		AttributesNotToCheck);
	
EndProcedure

Procedure CheckTMTSVOfOperation(AddlParameters, AttributesNotToCheck, Cancel)
	
	AttributesNotToCheck.Add("InventoryInOperation.FixedAsset");
	AttributesNotToCheck.Add("InventoryInOperation.ExpenseItem");
	AttributesNotToCheck.Add("InventoryInOperation.DimensionOfExpenses");
	
	TemplateFieldIsNotFilledIn = NStr("vi = 'Chưa điền cột ""%1"" tại dòng %2 trong danh sách ""Vật tư đang sử dụng""';
										|ru = 'Не заполнена колонка ""%1"" в строке %2 списка ""ТМЦ в эксплуатации""';
										|en = 'The ""%1"" column in the %2 line of the ""Inventory in operation"" list is not filled in'; fa = 'The ""%1"" column in the %2 line of the ""Inventory in operation"" list is not filled in';
										|it = 'Colonna ""%1"" non compilata nella riga %2 dell''elenco ""Beni materiali in lavorazione""';
										|pl = 'Nie wypełniono kolumny ""%1"" w wierszu %2 listy ""Zapasy w eksploatacji""';
										|tr = '""Kullanımdaki stok"" listesinin %2 satırındaki ""%1"" sütunu doldurulmamış'");
	
	QueryText = 
	"SELECT
	|	TabularSection.LineNumber AS LineNumber,
	|	CAST(TabularSection.OperationCategory AS Catalog.OperationCategories) AS OperationCategory,
	|	CAST(TabularSection.ExpenseItem AS ChartOfCharacteristicTypes.ExpenseItems) AS ExpenseItem,
	|	TabularSection.StartDateOfOperation AS StartDateOfOperation,
	|	TabularSection.FixedAsset AS FixedAsset
	|INTO TabularSection
	|FROM
	|	&TabularSection AS TabularSection
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CheckResult.LineNumber AS LineNumber,
	|	CheckResult.FixedAssetIsNotFilledIn AS FixedAssetIsNotFilledIn,
	|	CheckResult.ExpenseItemIsNotFilledIn AS ExpenseItemIsNotFilledIn
	|	
	|FROM
	|	(SELECT
	|		TabularSection.LineNumber AS LineNumber,
	|
	|		ISNULL(TabularSection.OperationCategory.AccountAsGroupFA, FALSE)
	|			AND TabularSection.FixedAsset = VALUE(Catalog.Assets.EmptyRef) AS FixedAssetIsNotFilledIn,
	|
	|		TabularSection.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			AND TabularSection.StartDateOfOperation < &BeginningOfApplicationOfFSBU5 
	|			AND TabularSection.StartDateOfOperation <> DATETIME(1,1,1) 
	|			AND NOT &CostDebited AS ExpenseItemIsNotFilledIn
	|
	|	FROM
	|		TabularSection AS TabularSection
	|
	|	) AS CheckResult
	|
	|WHERE
	|	(CheckResult.FixedAssetIsNotFilledIn
	|		OR CheckResult.ExpenseItemIsNotFilledIn)";
	
	Query = New Query(QueryText);
	Query.SetParameter("TabularSection", InventoryInOperation.Unload());
	Query.SetParameter("BeginningOfApplicationOfFSBU5", LocalAccntingClientServer.BeginningOfApplicationFSBU5_2019());
	Query.SetParameter("CostDebited", AddlParameters.CostDebited);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
	
		If Selection.FixedAssetIsNotFilledIn Then
			MessageText = StrTemplate(TemplateFieldIsNotFilledIn, NStr("vi = 'Tài sản cố định';
																		|ru = 'Основное средство';
																		|en = 'Fixed asset'; fa = 'دارایی ثابت';
																		|it = 'Capitale fisso';
																		|pl = 'Środek trwały';
																		|tr = 'Sabit kıymetler'"), Selection.LineNumber);
			Field = CommonClientServer.PathToTabularSection("InventoryInOperation", Selection.LineNumber, "FixedAsset");
			Common.MessageToUser(MessageText, ThisObject, Field, "Object", Cancel);
		EndIf;
	
		If Selection.ExpenseItemIsNotFilledIn Then
			MessageText = StrTemplate(TemplateFieldIsNotFilledIn, NStr("vi = 'Dạng chi phí';
																		|ru = 'Статья расходов';
																		|en = 'Expense item'; fa = 'قلم هزینه';
																		|it = 'Voce di spese';
																		|pl = 'Rodzaj kosztu';
																		|tr = 'Gider kalemi'"), Selection.LineNumber);
			Field = CommonClientServer.PathToTabularSection("InventoryInOperation", Selection.LineNumber, "ExpenseItem");
			Common.MessageToUser(MessageText, ThisObject, Field, "Object", Cancel);
		EndIf;
	
	EndDo;

EndProcedure

Function AddlParameters()
	
	AddlParameters = New Structure;
	AddlParameters.Insert("CostDebited", True);
	
	
	Return AddlParameters;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
