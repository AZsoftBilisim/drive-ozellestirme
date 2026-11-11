#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowRead
	|WHERE
	|	(Object <> UNDEFINED
	|		AND ValueAllowed(Object)
	|	OR Object = UNDEFINED
	|		AND ValueAllowed(Organization)
	|		AND ValueAllowed(Partner)
	|	)
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	(Object <> UNDEFINED
	|		AND ValueAllowed(Object)
	|	OR Object = UNDEFINED
	|		AND ValueAllowed(Organization)
	|		AND ValueAllowed(Partner)
	|	)";

EndProcedure

// End StandardSubsystems.AccessManagement

// Called when replacing duplicates in the Attributes of elements.
//
// Parameters:
//  ReplacementPairs - Map of KeyAndValue - contains the original and duplicate value pairs.
//  UnprocessedOriginalsValues - Array of Structure:
//    * ValueToReplace - AnyRef - the original value of the object being replaced.
//    * UsedLinks - See Common.SubordinateObjectsLinksByTypes
//    * KeyAttributesValue - Structure - Key - name of the item, value-value of the item.
//
Procedure OnSearchForReferenceReplacement(ReplacementPairs, UnprocessedOriginalsValues) Export
	
	For Each UnprocessedDuplicate In UnprocessedOriginalsValues Do
		ValueToReplace = UnprocessedDuplicate.ValueToReplace;
		KeyAttributesValue = UnprocessedDuplicate.KeyAttributesValue;
		
		Attributes = New Array;
		For Each Item In KeyAttributesValue Do
			Attributes.Add(Item.Key);
		EndDo;
		ValuesOfDetailsOfDouble = Common.ObjectAttributesValues(ValueToReplace, Attributes);
		
		SearchDetails_ = New Structure;
		AttributesToCreate = New Structure;
		For Each KeyAttribute In KeyAttributesValue Do
			ValueOfOriginal = ReplacementPairs.Get(KeyAttribute.Value);
			SearchDetails_.Insert(KeyAttribute.Key, ?(ValueOfOriginal = Undefined, KeyAttribute.Value, ValueOfOriginal));
			AttributesToCreate.Insert(KeyAttribute.Key, ValuesOfDetailsOfDouble[KeyAttribute.Key]);
		EndDo;
		
		// @skip-check query-in-loop - otherwise it is impossible to understand whether such a key exists or not
		ReplacementPairs.Insert(ValueToReplace, CreateByKey(SearchDetails_, AttributesToCreate));
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Ref");
	Fields.Add("Object");
	Fields.Add("Description");
	Fields.Add("RefType");
	Fields.Add("PaymentType_");
	Fields.Add("ARAPObjectType");
	Fields.Add("SourceDocumentName");
	Fields.Add("IncomingDocumentNumber");
	Fields.Add("IncomingDocumentDate");
	Fields.Add("Date");
	Fields.Add("Number");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	If Not ValueIsFilled(Data.Object) And ValueIsFilled(Data.Ref) Then
		Presentation = NStr("vi = '<Trống>';
							|ru = '<Пустой>';
							|en = '<Empty>'; fa = '<Empty>';
							|it = '<Vuoto>';
							|pl = '<Pusty>';
							|tr = '<Boş>'");
		StandardProcessing = False;
	ElsIf Data.PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.VendorARAPAccounting")
		And Data.ARAPObjectType = PredefinedValue("Enum.ARAPObjectTypes.Invoice") Then
		
		Data.Insert("ExternalDocumentName", Data.SourceDocumentName);
		TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
		Data, Presentation, StandardProcessing, Data.RefType);
		
	Else
		Presentation = Data.Description;   
		StandardProcessing = False;
		#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		If Not NationalLanguageSupportCached.ConfigurationUsesOnlyOneLanguage(False) Then
			
			If ValueIsFilled(Data.Object) And Data.ARAPObjectType <> PredefinedValue("Enum.ARAPObjectTypes.Contract") Then
				Presentation = TMCommonUseClientServer.StandardDocumentPresentation(Data.RefType, Data.Number, Data.Date);
			EndIf;
			
		EndIf;
		#EndIf
		
	EndIf;
	
EndProcedure

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ObjectForm" Then
		#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
			DebuggingMode = Common.DebugMode();
		#Else
			DebuggingMode = CommonClient.DebugMode();
		#EndIf
		
		If Not DebuggingMode Then
			If Parameters.Property("Key") And ValueIsFilled(Parameters.Key) Then
				Result= ARAPAccountingServerCall.FormOfCalculationObject(Parameters.Key);
				If Result.Form <> "" Then
					StandardProcessing = False;
					SelectedForm = Result.Form;
					Parameters.Key = Result.Key;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	Filter = New Structure();
	Filter.Insert("IsInternal", False);
	
	Parameters.Insert("Filter", Filter);
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.ARAPObjects.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.25.39";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("51119c20-5762-5c1b-bdf7-2f9a8da27bec");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.ARAPObjects.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật danh mục ""Đối tượng hạch toán"":';
								|ru = 'Обновление справочника ""Объекты расчетов"":';
								|en = 'Update the ""AR/AP objects"" catalog:'; fa = 'Update the ""AR/AP objects"" catalog:';
								|it = 'Update the ""AR/AP objects"" catalog:';
								|pl = 'Update the ""AR/AP objects"" catalog:';
								|tr = '""Alacak/Borç nesneleri"" kataloğunun güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền dấu hiệu ""Biểu ghi hạch toán công nợ được phân chia theo lĩnh vực hoạt động""';
								|ru = '- Заполнение признака ""Регистры взаиморасчетов делятся по направлениям деятельности""';
								|en = '- Fill in the ""AR/AP accounting registers are divided by lines of business"" flag'; fa = '- Fill in the ""AR/AP accounting registers are divided by lines of business"" flag';
								|it = '- Fill in the ""AR/AP accounting registers are divided by lines of business"" flag';
								|pl = '- Fill in the ""AR/AP accounting registers are divided by lines of business"" flag';
								|tr = '- ""Alacak/Borç muhasebesi kayıtları iş kollarına göre ayrılmaktadır"" işaretinin doldurulması'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	// Affects the conduct of mutual settlements
	Handler.Order = Enums.OrderOfUpdateHandlers.Crucial;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.ARAPObjects.FullName());
	// Accumulation registers.Calculation by clients, accumulation registers.Calculations by suppliers - dirty reading is allowed
	// The current handler does not require pre-execution of the calculation register update handlers
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.ARAPObjects.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.ARAPObjects.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.OrderingFieldsOnUserOperations.Add("DATE DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("DATE DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();

	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	Catalog.Ref AS ARAPObject
	|FROM
	|	Catalog.ARAPObjects AS Catalog
	|		LEFT JOIN AccumulationRegister.CustomersARAPAccounting AS SNDRegisterEntries
	|			ON SNDRegisterEntries.ARAPObject = Catalog.Ref
	|				AND SNDRegisterEntries.AccountingDimensionByPartners.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	Catalog.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness <> (SNDRegisterEntries.ARAPObject IS NULL)
	|	AND Catalog.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Catalog.Ref AS ARAPObject
	|FROM
	|	Catalog.ARAPObjects AS Catalog
	|		LEFT JOIN AccumulationRegister.VendorsARAPAccounting AS SNDRegisterEntries
	|			ON SNDRegisterEntries.ARAPObject = Catalog.Ref
	|				AND SNDRegisterEntries.AccountingDimensionByPartners.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	Catalog.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness <> (SNDRegisterEntries.ARAPObject IS NULL)
	|	AND Catalog.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Catalog.Ref AS ARAPObject
	|FROM
	|	Catalog.ARAPObjects AS Catalog
	|		INNER JOIN Catalog.LinesOfBusiness AS Direction
	|			ON Direction.Ref = Catalog.LineOfBusiness
	|WHERE
	|	NOT Direction.IncomeAccounting AND Catalog.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|	OR NOT Direction.VendorARAP AND Catalog.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|	
	|";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("ARAPObject"));
	
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
	ExceptionsWhenUpdating = New Array;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	DataForUpdate.Ref AS Ref
		|INTO TableOfElements
		|FROM
		|	&DataForUpdate AS DataForUpdate
		|INDEX BY Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NestedQuery.Ref AS Ref,
		|	MAX(NestedQuery.ThereAreSNDRecords) AS ThereAreSNDRecords
		|FROM (
		|	SELECT
		|		TableOfElements.Ref AS Ref,
		|		ISNULL(CustomersARAPAccounting.AccountingDimensionByPartners.LineOfBusiness,VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|				 <> VALUE(Catalog.LinesOfBusiness.EmptyRef) AS ThereAreSNDRecords
		|	FROM
		|		TableOfElements AS TableOfElements
		|			LEFT JOIN AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
		|				ON TableOfElements.Ref = CustomersARAPAccounting.ARAPObject
		|	WHERE
		|		CustomersARAPAccounting.ARAPObject IN (SELECT Ref FROM TableOfElements)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TableOfElements.Ref AS Ref,
		|		ISNULL(VendorsARAPAccounting.AccountingDimensionByPartners.LineOfBusiness,VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|				 <> VALUE(Catalog.LinesOfBusiness.EmptyRef) AS ThereAreSNDRecords
		|	FROM
		|		TableOfElements AS TableOfElements
		|			LEFT JOIN AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
		|				ON TableOfElements.Ref = VendorsARAPAccounting.ARAPObject) AS NestedQuery
		|GROUP BY
		|	NestedQuery.Ref 
		|";
	
	Query.SetParameter("DataForUpdate", UpdatedData);
	
	Catalog = Query.Execute().Select();
	
	While Catalog.Next() Do
		
		ExceptionReason = "";
		Recommendation = "";
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = "Block";
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Catalog.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			CatalogObject = Catalog.Ref.GetObject(); // CatalogObject
			
			ExceptionReason = "BadData";
			Recommendation = NStr("vi = 'Hãy kiểm tra thủ công dữ liệu của danh mục.';
									|ru = 'Проверьте данные справочника вручную.';
									|en = 'Check the catalog data manually.'; fa = 'Check the catalog data manually.';
									|it = 'Проверьте данные справочника вручную.';
									|pl = 'Check the catalog data manually.';
									|tr = 'Dizin verilerini manuel olarak kontrol edin.'");
			
			If CatalogObject <> Undefined Then
				
				// Filling in the register of accountsweeklyatesnotesreferences
				If CatalogObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness <> (Not Catalog.ThereAreSNDRecords) Then
					CatalogObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness = Not Catalog.ThereAreSNDRecords;
				EndIf;
				
				// Cleaning up the wrong LB
				If ValueIsFilled(CatalogObject.LineOfBusiness) Then
					AttributeValuesOfLB = Common.ObjectAttributesValues(CatalogObject.LineOfBusiness, "IncomeAccounting,VendorARAP");
					If CatalogObject.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting And Not AttributeValuesOfLB.IncomeAccounting
						Or CatalogObject.PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting And Not AttributeValuesOfLB.VendorARAP Then
							CatalogObject.LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
					EndIf;
				EndIf;
			EndIf;
			
			ExceptionReason = "Record";
			
			If CatalogObject.Modified() Then
				InfobaseUpdate.WriteData(CatalogObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Catalog.Ref);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Catalog.Ref);
			
			If ExceptionReason = "BadData" Then
				
				IssueDetails = InfobaseUpdateTM.DataProblem(
					Catalog.Ref, Recommendation, ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
				
			ElsIf ExceptionReason = "Record" Then
				
				InfobaseUpdateTM.RecordBadData(
					ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
				Raise StrConcat(NStr("vi = 'Không thể xử lý phần tử danh mục ""Đối tượng hạch toán"".';
									|ru = 'Не удалось обработать элемент справочника ""Объекты расчетов"".';
									|en = 'Cannot process the ""AR/AP objects"" catalog item.'; fa = 'Cannot process the ""AR/AP objects"" catalog item.';
									|it = 'Cannot process the ""AR/AP objects"" catalog item.';
									|pl = 'Cannot process the ""AR/AP objects"" catalog item.';
									|tr = '""Alacak/Borç nesneleri"" kataloğunun öğesi işlenemedi.'"), Chars.LF);
				
			EndIf;
			
		EndTry;
		
	EndDo;
	
	If ObjectsProcessed > 0 Then
		InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
	EndIf;
	
	Parameters.ProcessingCompleted =
		InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

// The list of Attributes used to determine the uniqueness of a directory item 
// See ARAPObjectsServer.CheckCreateCalculationObject, the object Details parameter.
// 
// Returns:
//   String
//
Function KeyAttributes() Export
	
	LinksFields = "Object, Organization, Counterparty, Partner, PaymentType_, ARAPCurrency, Contract";
	Return LinksFields;
	
EndFunction

// Creates a new key field-AR/AP object or returns an existing one.
//
// Parameters:
//  SearchParameters - Structure of KeyAndValue:
//   * Key     - String - name of the prop. See KeyAttributes.
//   * Value - Arbitrary - the value of the props.
//  CreationParameters - Structure of KeyAndValue:
//   * Key     - String - name of the prop. See KeyAttributes.
//   * Value - Arbitrary - the value of the props.
//
// Returns:
//   CatalogRef.ARAPObjects
//
Function CreateByKey(SearchParameters, CreationParameters) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ARAPObjects.Ref AS Ref
	|FROM
	|	Catalog.ARAPObjects AS ARAPObjects
	|WHERE
	|	ARAPObjects.Object = &Object
	|	AND ARAPObjects.Organization = &Organization
	|	AND ARAPObjects.Counterparty = &Counterparty
	|	AND ARAPObjects.Partner = &Partner
	|	AND ARAPObjects.PaymentType_ = &PaymentType_
	|	AND ARAPObjects.ARAPCurrency = &ARAPCurrency
	|	AND ARAPObjects.Contract = &Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	*
	|FROM
	|	Catalog.ARAPObjects AS ARAPObjects
	|WHERE
	|	ARAPObjects.Object = &Object_Filling
	|	AND ARAPObjects.Organization = &CompanyFillingIn
	|	AND ARAPObjects.Counterparty = &CounterpartyFillingIn
	|	AND ARAPObjects.Partner = &PartnerFillingIn
	|	AND ARAPObjects.PaymentType_ = &TypeOfCalculationsFillingIn
	|	AND ARAPObjects.ARAPCurrency = &SettlementCurrencyFillingIn
	|	AND ARAPObjects.Contract = &ContractFillingOut";
	
	Query.SetParameter("Object", SearchParameters.Object);
	Query.SetParameter("Organization", SearchParameters.Organization);
	Query.SetParameter("Counterparty", SearchParameters.Counterparty);
	Query.SetParameter("Partner", SearchParameters.Partner);
	Query.SetParameter("PaymentType_", SearchParameters.PaymentType_);
	Query.SetParameter("ARAPCurrency", SearchParameters.ARAPCurrency);
	Query.SetParameter("Contract", SearchParameters.Contract);
	
	Query.SetParameter("Object_Filling", CreationParameters.Object);
	Query.SetParameter("CompanyFillingIn", CreationParameters.Organization);
	Query.SetParameter("CounterpartyFillingIn", CreationParameters.Counterparty);
	Query.SetParameter("PartnerFillingIn", CreationParameters.Partner);
	Query.SetParameter("TypeOfCalculationsFillingIn", CreationParameters.PaymentType_);
	Query.SetParameter("SettlementCurrencyFillingIn", CreationParameters.ARAPCurrency);
	Query.SetParameter("ContractFillingOut", CreationParameters.Contract);
	
	SetPrivilegedMode(True);
	QueryResult = Query.ExecuteBatch();
	If QueryResult[0].IsEmpty() Then
		Selection = QueryResult[1].Select();
		Selection.Next();
		Var_Key = Catalogs.ARAPObjects.CreateItem();
		FillPropertyValues(Var_Key, Selection);
		FillPropertyValues(Var_Key, SearchParameters);
		
		SelectionAdditionalDetails = Selection.AdditionalAttributes; // QueryResult -
		AdditionalAttributes = SelectionAdditionalDetails.Select(); 
		While AdditionalAttributes.Next() Do
			NewRow = Var_Key.AdditionalAttributes.Add();
			FillPropertyValues(NewRow, AdditionalAttributes);
		EndDo;
		
		Var_Key.Write();
	Else
		Var_Key = QueryResult[0].Select();
		Var_Key.Next();
	EndIf;
	SetPrivilegedMode(False);
	
	Return Var_Key.Ref;
	
EndFunction

#EndRegion

#EndIf