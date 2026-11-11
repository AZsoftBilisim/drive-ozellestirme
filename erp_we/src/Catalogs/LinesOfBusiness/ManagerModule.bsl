#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//  Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	Result.Add("IncomeAccounting");
	Result.Add("CostAccounting");
	Result.Add("ExcessOfAssignedGoodsAndLaborDemandIsAllowed");
	Result.Add("VendorARAP");
	Result.Add("FixedAndIntangibleAssetsAccounting");
	Result.Add("CashManagement;DSAccountingGroup");
	Result.Add("VATTaxation;VATTaxation");
	Result.Add("VATTaxationIsDeterminedInDocuments;TaxationTreatmentIsDefinedByValue,TheTaxRegimeIsDefinedInTheDocument");
	Result.Add("ExecutionOfGovernmentContracts");
	
	LinesOfBusinessLocalization.AddBlockedItemDetails(Result);
	
	Return Result;
	
EndFunction

// Return a sign of accounting by business line
//
// 
// Returns:
//  Boolean - Accounting by direction is used
//
Function AccountingByDirectionsIsUsed() Export
	Return GetFunctionalOption("UseCostAccountingByLinesOfBusiness")
			Or GetFunctionalOption("UseFixedAssetAccountingByActivities")
			Or GetFunctionalOption("UseVendorARAPInLineOfBusiness")
			Or GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness")
			Or GetFunctionalOption("UseCashAndBankAccountsOfLinesOfBusinessOnSeparateAccountsAndCashAccounts")
			Or GetFunctionalOption("UseCashAndBankAccountsForLinesOfBusinessByCorrespondence");
EndFunction

// Returns parameters for filling In the taxing detailsprodazhi
//
// 
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function FillingParametersTaxationVATSales() Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	FillParameters.Date = CurrentSessionDate();
	FillParameters.GoodsSales = True;
	FillParameters.ImplementationOfWorksServices = True;
	FillParameters.ThisIsOrder = True;
	
	Return FillParameters;
	
EndFunction

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	
	Query = New Query;
	
	If Parameters.ChoiceFoldersAndItems = FoldersAndItemsUse.Items Then
		FIlterRow = " AND LinesOfBusiness.Status = &Status";
	ElsIf Parameters.ChoiceFoldersAndItems = FoldersAndItemsUse.Folders Then
		FIlterRow = " AND LinesOfBusiness.IsFolder";
	Else
		FIlterRow = " AND (LinesOfBusiness.Status = &Status OR LinesOfBusiness.IsFolder)";
	EndIf;
	Query.SetParameter("Status", Enums.LineOfBusinessStatuses.Used);
	
	If Parameters.Property("Filter") Then
		
		If Parameters.Filter.Property("CostsOrVendorsARAPAccounting") And Parameters.Filter.CostsOrVendorsARAPAccounting Then
			
			FIlterRow = FIlterRow + " AND (LinesOfBusiness.CostAccounting = TRUE
				|OR LinesOfBusiness.VendorARAP = TRUE)";
			
		EndIf;
		
		If Parameters.Filter.Property("CostOrCustomersARAPAccounting")
		   And Parameters.Filter.CostOrCustomersARAPAccounting Then
			
			FIlterRow = FIlterRow + " AND (LinesOfBusiness.CostAccounting = TRUE
				|OR LinesOfBusiness.IncomeAccounting = TRUE)";
			
		EndIf;
		
		If Parameters.Filter.Property("StateContractAndSDOContractFulfillment") Then
			
			FIlterRow = FIlterRow + " AND LinesOfBusiness.StateContractAndSDOContractFulfillment = &StateContractAndSDOContractFulfillment";
			Query.SetParameter("StateContractAndSDOContractFulfillment", Parameters.Filter.StateContractAndSDOContractFulfillment);
			
		EndIf;
		
		If Parameters.Filter.Property("Ref") Then
			
			FIlterRow = FIlterRow + " AND LinesOfBusiness.Ref IN (&Ref)";
			Filter = Parameters.Filter;// Structure
			Query.SetParameter("Ref", Filter.Ref);
			
		EndIf;
		
		// The selection parameters may specify the Attributes of the line of business with the Boolean type.
		MetaAttributes = Metadata.Catalogs.LinesOfBusiness.Attributes;
		BooleanType = Type("Boolean");
		
		For Each KeyAndValue In Parameters.Filter Do
			
			If TypeOf(KeyAndValue.Value) = BooleanType Then
				
				MetaAttribute = MetaAttributes.Find(KeyAndValue.Key);
				
				If MetaAttribute <> Undefined And MetaAttribute.Type.ContainsType(BooleanType) Then
					FIlterRow = FIlterRow + "
						|	AND LinesOfBusiness." + KeyAndValue.Key + " = " + ?(KeyAndValue.Value, "TRUE", "FALSE") + "
						|";
				EndIf;
			 	
		 	EndIf;
		 	
		EndDo;
		
	EndIf;
	
	If Parameters.Property("Ref") Then
		
		If TypeOf(Parameters.Ref) = Type("CatalogRef.CounterpartyContracts")
			And Parameters.Property("ContractType") Then
			
			If Parameters.ContractType = Enums.ContractTypes.WithCustomer
				Or Parameters.ContractType = Enums.ContractTypes.WithConsignee Then
				
				FIlterRow = FIlterRow + " AND LinesOfBusiness.IncomeAccounting = TRUE";
			ElsIf Parameters.ContractType = Enums.ContractTypes.ReceiptForTolling2_5
				Or False Then
				
				FIlterRow = FIlterRow + " AND ((LinesOfBusiness.CostAccounting = FALSE AND LinesOfBusiness.IncomeAccounting = TRUE)
					|OR (LinesOfBusiness.CostAccounting = TRUE AND LinesOfBusiness.IncomeAccounting = TRUE))";
			ElsIf Parameters.ContractType = Enums.ContractTypes.WithVendor
				Or Parameters.ContractType = Enums.ContractTypes.WithConsignor
				Or Parameters.ContractType = Enums.ContractTypes.Import
				Or Parameters.ContractType = Enums.ContractTypes.PurchaseEAEU
				Or Parameters.ContractType = Enums.ContractTypes.ReceivingForCustody Then
				
				FIlterRow = FIlterRow + " AND (LinesOfBusiness.CostAccounting = TRUE
					|OR LinesOfBusiness.VendorARAP = TRUE)";
				
			Else
				
				FIlterRow = FIlterRow + " AND LinesOfBusiness.CostAccounting = TRUE";
				
			EndIf;
			
		ElsIf TypeOf(Parameters.Ref) = Type("DocumentRef.IntercompanyGoodsReturn")
			Or TypeOf(Parameters.Ref) = Type("DocumentRef.MovementOfOtherAssetsAndLiabilities")
			Or TypeOf(Parameters.Ref) = Type("DocumentRef.CommissionReportIntercompany")
			Or TypeOf(Parameters.Ref) = Type("DocumentRef.CommissionWriteOffReportIntercompany")
			Or TypeOf(Parameters.Ref) = Type("DocumentRef.CustomerInvoiceIntercompany")
			Or TypeOf(Parameters.Ref) = Type("DocumentRef.GoodsMisgrading")
			Or TypeOf(Parameters.Ref) = Type("DocumentRef.OtherIncomeExpenses")
			Or TypeOf(Parameters.Ref) = Type("CatalogRef.IntercompanyContracts") Then
			
			FIlterRow = FIlterRow + " AND (LinesOfBusiness.IncomeAccounting = TRUE
				|	OR LinesOfBusiness.CostAccounting = TRUE 
				|	OR LinesOfBusiness.VendorARAP = TRUE)";
			
		EndIf;
		
	EndIf;
	
	SearchString = ?(Parameters.SearchString = Undefined, "", Parameters.SearchString);
	Query.SetParameter("InputString", Common.GenerateSearchQueryString(SearchString) + "%" );
	
	Query.Text = "SELECT ALLOWED TOP 50
		|	LinesOfBusiness.Ref AS Ref,
		|	PRESENTATION(LinesOfBusiness.Ref) AS Presentation,
		|	LinesOfBusiness.DeletionMark AS DeletionMark
		|FROM
		|	Catalog.LinesOfBusiness AS LinesOfBusiness
		|WHERE
		|	&SearchTerms" + FIlterRow;
	
	SearchTerms = "LinesOfBusiness.Description LIKE &InputString ESCAPE ""~""";
	
	For AdditionalLanguageNumber = 1 To NationalLanguageSupportServer.AdditionalLanguagesCount() Do
		
		If NationalLanguageSupportServer.IsAdditionalLangUsed(AdditionalLanguageNumber) Then
			
			LanguageConstantName = NationalLanguageSupportServer.LanguageConstantName(AdditionalLanguageNumber);
			If Metadata.Constants.Find(LanguageConstantName) = Undefined Then
				
				Continue;
				
			EndIf;
			
			AttributesNames = NationalLanguageSupportServer.AttributesNamesConsideringLangCode("Description", Constants[LanguageConstantName].Get());
			SearchTerms = SearchTerms + "
			|	OR " + StringFunctionsClientServer.SubstituteParametersToString("LinesOfBusiness.%1 LIKE &InputString ESCAPE ""~""",
				AttributesNames["Description"]);
			
		EndIf;
		
	EndDo;
	
	Query.Text = StrReplace(Query.Text, "&SearchTerms", "(" + SearchTerms + ")");
	
	Selection = Query.Execute().Select();
	ChoiceData = New ValueList;
	While Selection.Next() Do
		TextPresentation = Selection.Presentation;
		If Selection.DeletionMark Then
			StructureValue = New Structure("Value, DeletionMark", Selection.Ref, Selection.DeletionMark);
			ChoiceData.Add(StructureValue, TextPresentation,, PictureLib.ItemMarkedForDeletion);
		Else
			ChoiceData.Add(Selection.Ref, TextPresentation);
		EndIf;
	EndDo;
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	
EndProcedure

#EndRegion

#Region Private

#Region Assignments

// Returns a template for generating product assignments in the document.
//
// Parameters:
// 	Object - CatalogObject.LinesOfBusiness, FormDataStructure - the business area for which you need to get the assignment template.
//
// Returns:
// 	See Catalogs.Assignments.NewSubmenuTemplate
//
Function DestinationPattern(Object) Export
	
	DestinationPattern = Catalogs.Assignments.NewSubmenuTemplate();
	
	If Object.CostAccounting Then
		
		DestinationPattern.LineOfBusiness = Object.Ref;
		
	EndIf;
	
	Return DestinationPattern;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.LinesOfBusiness.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.24.25";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("7fde082f-8db7-487a-94ca-0f2f9de143a3");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.LinesOfBusiness.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật danh mục ""Lĩnh vực hoạt động"":';
								|ru = 'Обновление справочника ""Направление деятельности"":';
								|en = 'Update the ""Line of business"" catalog:'; fa = 'Update the ""Line of business"" catalog:';
								|it = 'Update the ""Line of business"" catalog:';
								|pl = 'Update the ""Line of business"" catalog:';
								|tr = '""İş kolu"" kataloğunun güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin đa ngôn ngữ của danh mục';
								|ru = '- Заполнение мультиязычных реквизитов справочника';
								|en = '- Fill multilingual catalog attributes'; fa = '- Fill multilingual catalog attributes';
								|it = '- Fill multilingual catalog attributes';
								|pl = '- Fill multilingual catalog attributes';
								|tr = '- Kataloğun çok dilli özniteliklerinin doldurulması'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.LinesOfBusiness.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.LinesOfBusiness.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.LinesOfBusiness.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	AdditionalLanguagesAreUsed = False;
	For Each AdditionalLanguageIsUsed In NationalLanguageSupportServer.LanguagesInfo().Used Do
		
		If AdditionalLanguageIsUsed.Value = True Then
			
			AdditionalLanguagesAreUsed = True;
			Break;
			
		EndIf;
		
	EndDo;
	
	If Not AdditionalLanguagesAreUsed Then
		
		Return;
		
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	LinesOfBusiness.Ref AS Ref
	|FROM
	|	Catalog.LinesOfBusiness AS LinesOfBusiness
	|WHERE
	|	NOT LinesOfBusiness.Description = """"
	|	AND LinesOfBusiness.DescriptionLanguage1 = """"
	|
	|UNION
	|
	|SELECT
	|	LinesOfBusiness.Ref AS Ref
	|FROM
	|	Catalog.LinesOfBusiness AS LinesOfBusiness
	|WHERE
	|	NOT LinesOfBusiness.Description = """"
	|	AND LinesOfBusiness.DescriptionLanguage2 = """"
	|
	|UNION
	|
	|SELECT
	|	LinesOfBusiness.Ref AS Ref
	|FROM
	|	Catalog.LinesOfBusiness AS LinesOfBusiness
	|WHERE
	|	NOT CAST(LinesOfBusiness.Comment AS STRING(150)) = """"
	|	AND CAST(LinesOfBusiness.CommentLanguage1 AS STRING(150)) = """"
	|
	|UNION
	|
	|SELECT
	|	LinesOfBusiness.Ref AS Ref
	|FROM
	|	Catalog.LinesOfBusiness AS LinesOfBusiness
	|WHERE
	|	NOT CAST(LinesOfBusiness.Comment AS STRING(150)) = """"
	|	AND CAST(LinesOfBusiness.CommentLanguage2 AS STRING(150)) = """"";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Parameters.ProcessingCompleted = False;
	
	FullObjectName = EmptyRef().Metadata().FullName();
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
		
	EndIf;
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	ExceptionsWhenUpdating = New Array;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Không thể xử lý danh mục ""Lĩnh vực hoạt động"" theo hàm sự kiện:';
								|ru = 'Не удалось обработать справочник ""Направление деятельности"" по обработчику:';
								|en = 'Cannot process the ""Line of business"" catalog by the handler:'; fa = 'Cannot process the ""Line of business"" catalog by the handler:';
								|it = 'Cannot process the ""Line of business"" catalog by the handler:';
								|pl = 'Cannot process the ""Line of business"" catalog by the handler:';
								|tr = 'İşleyici tarafından ""İş kolu"" kataloğu işlenemedi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin đa ngôn ngữ của danh mục';
								|ru = '- Заполнение мультиязычных реквизитов справочника';
								|en = '- Fill multilingual catalog attributes'; fa = '- Fill multilingual catalog attributes';
								|it = '- Fill multilingual catalog attributes';
								|pl = '- Fill multilingual catalog attributes';
								|tr = '- Kataloğun çok dilli özniteliklerinin doldurulması'"));
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DataForUpdate.Ref AS Ref
	|INTO TT
	|FROM
	|	&DataForUpdate AS DataForUpdate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.Ref AS Ref,
	|	LinesOfBusiness.DataVersion AS DataVersion
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.LinesOfBusiness AS LinesOfBusiness
	|		ON TT.Ref = LinesOfBusiness.Ref";
	
	Query.SetParameter("DataForUpdate", UpdatedData);
	
	Catalog = Query.Execute().Select();
	
	While Catalog.Next() Do
		
		ExceptionReason = 0;
		Recommendation = "";
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = 1; // IObjectLock
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Catalog.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			CatalogObject = InfobaseUpdateTM.CheckGetObject(
				Catalog.Ref, Catalog.DataVersion, Parameters.Queue); // CatalogObject
			
			ExceptionReason = 2; // BadData
			Recommendation = NStr("vi = 'Hãy kiểm tra thủ công dữ liệu của danh mục.';
									|ru = 'Проверьте данные справочника вручную.';
									|en = 'Check the catalog data manually.'; fa = 'Check the catalog data manually.';
									|it = 'Проверьте данные справочника вручную.';
									|pl = 'Check the catalog data manually.';
									|tr = 'Dizin verilerini manuel olarak kontrol edin.'");
			
			ObjectModified = False;
			
			If CatalogObject <> Undefined Then
				
				If ValueIsFilled(CatalogObject.Description) Then
					
					If Not ValueIsFilled(CatalogObject.DescriptionLanguage1) Then
						
						CatalogObject.DescriptionLanguage1 = CatalogObject.Description;
						
					EndIf;
					
					If Not ValueIsFilled(CatalogObject.DescriptionLanguage2) Then
						
						CatalogObject.DescriptionLanguage2 = CatalogObject.Description;
						
					EndIf;
					
				EndIf;
				
				If ValueIsFilled(CatalogObject.Comment) Then
					
					If Not ValueIsFilled(CatalogObject.CommentLanguage1) Then
						
						CatalogObject.CommentLanguage1 = CatalogObject.Comment;
						
					EndIf;
					
					If Not ValueIsFilled(CatalogObject.CommentLanguage2) Then
						
						CatalogObject.CommentLanguage2 = CatalogObject.Comment;
						
					EndIf;
					
				EndIf;
				
				ObjectModified = True;
				
			EndIf;
			
			ExceptionReason = 3; // Record
			
			If ObjectModified Then
				InfobaseUpdate.WriteData(CatalogObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Catalog.Ref);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Catalog.Ref);
			
			If ExceptionReason = 2 Then
				
				IssueDetails = InfobaseUpdateTM.DataProblem(
					Catalog.Ref, Recommendation, ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
				
			ElsIf ExceptionReason = 3 Then
				
				InfobaseUpdateTM.RecordBadData(
					ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
				Raise StrConcat(ListOfDescriptions, Chars.LF);
				
			EndIf;
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted =
		InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion


#EndRegion

#EndIf
