#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Not ProductRangeServer.TypesOfPricesChangesInAssortmentComplyWithRules(ThisObject) Then
		Cancel = True;
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
	If Not ValueIsFilled(Stage) Then
		NotCheckedAttributeArray.Add("Phase");
	EndIf;
	
	UseStoreFormats = GetFunctionalOption("UseStoreFormats");
	
	If Not ValueIsFilled(PlanningObject) 
		Or UseStoreFormats And TypeOf(PlanningObject) = Type("CatalogRef.Warehouses")
		Or Not UseStoreFormats And TypeOf(PlanningObject) = Type("CatalogRef.StoreFormats") Then
		
		PlanningObjectErrorPattern = NStr("vi = 'Chưa điền trường ""%PlanningObject_%""';
											|ru = 'Поле ""%PlanningObject_%"" не заполнено';
											|en = '""%PlanningObject_%"" is required.'; fa = '""%PlanningObject_%"" is required.';
											|it = 'Il campo ""%PlanningObject_%"" non è compilato';
											|pl = 'Nie wypełniono pola ""%PlanningObject_%""';
											|tr = '""%PlanningObject_%"" alanı doldurulmadı'");
		If UseStoreFormats Then
			PresentationOfPlanningObject = NStr("vi = 'Khuôn dạng cửa hàng';
												|ru = 'Формат магазина';
												|en = 'Store format'; fa = 'قالب فروشگاه';
												|it = 'Formato del negozio';
												|pl = 'Format sklepu';
												|tr = 'Mağaza formatı'");
		Else
			PresentationOfPlanningObject = NStr("vi = 'Cửa hàng/kho bãi';
												|ru = 'Магазин/склад';
												|en = 'Store/warehouse'; fa = 'Store/warehouse';
												|it = 'Magazzino/deposito';
												|pl = 'Sklep/magazyn';
												|tr = 'Mağaza/ambar'");
		EndIf;
		
		CommonClientServer.MessageToUser(
			StrReplace(PlanningObjectErrorPattern, "%PlanningObject_%", PresentationOfPlanningObject),
			ThisObject,
			"PlanningObject",
			,
			Cancel);
	
	EndIf;
	
	If Operation <> Enums.ProductRangeChangeTransactions.CollectionManagement Then
	
		NotCheckedAttributeArray.Add("ItemsCollection");
		NotCheckedAttributeArray.Add("PurchaseStartDate");
		NotCheckedAttributeArray.Add("PurchaseRestrictionDate");
		NotCheckedAttributeArray.Add("SalesStartDate");
		NotCheckedAttributeArray.Add("SalesRestrictionDate");
	
	EndIf; 
	
	If Operation <> Enums.ProductRangeChangeTransactions.ChangeInProductRange Then
	
		NotCheckedAttributeArray.Add("Stage");
		NotCheckedAttributeArray.Add("Phase");
		
	EndIf; 
	
	If Operation = Enums.ProductRangeChangeTransactions.CollectionManagement Then
		If ValueIsFilled(PurchaseStartDate) 
			And ValueIsFilled(PurchaseRestrictionDate) 
			And PurchaseStartDate = PurchaseRestrictionDate Then
		
			CommonClientServer.MessageToUser(
				NStr("vi = 'Kỳ mua hàng phải lớn hơn một ngày.';
					|ru = 'Период закупок должен быть больше одного дня.';
					|en = 'Purchase period should be longer than one day.'; fa = 'Purchase period should be longer than one day.';
					|it = 'Il periodo di approvvigionamento deve essere superiore a un giorno.';
					|pl = 'Okres zakupów musi być dłuższy niż jeden dzień.';
					|tr = 'Satın alma süresi bir günden fazla olmalıdır.'"),
				ThisObject,
				"PurchaseRestrictionDate",
				,
				Cancel);
		
		EndIf; 
		
		If ValueIsFilled(SalesStartDate) 
			And ValueIsFilled(SalesRestrictionDate) 
			And SalesStartDate = SalesRestrictionDate Then
		
			CommonClientServer.MessageToUser(
				NStr("vi = 'Kỳ bán hàng phải lớn hơn một ngày.';
					|ru = 'Период продаж должен быть больше одного дня.';
					|en = 'Sales period should be longer than one day.'; fa = 'Sales period should be longer than one day.';
					|it = 'Il periodo di vendite deve essere superiore a un giorno.';
					|pl = 'Okres sprzedaży musi być dłuższy niż jeden dzień.';
					|tr = 'Satış süresi bir günden fazla olmalıdır.'"),
				ThisObject,
				"SalesRestrictionDate",
				,
				Cancel);
		
		EndIf;
		
		If ValueIsFilled(PurchaseStartDate) 
			And ValueIsFilled(PurchaseRestrictionDate) 
			And PurchaseStartDate > PurchaseRestrictionDate Then
		
			CommonClientServer.MessageToUser(
				NStr("vi = 'Ngày kết thúc mua hàng nhỏ hơn ngày bắt đầu.';
					|ru = 'Дата окончания закупок меньше чем дата начала.';
					|en = 'Purchase end date is earlier than the start date.'; fa = 'Purchase end date is earlier than the start date.';
					|it = 'La data di fine degli acquisti è precedente alla data di inizio.';
					|pl = 'Data zakończenia zakupu jest mniejsza niż data początku.';
					|tr = 'Satın alma bitiş tarihi, başlangıç ​​tarihinden daha önce.'"),
				ThisObject,
				"PurchaseRestrictionDate",
				,
				Cancel);
		
		EndIf;
		
		If ValueIsFilled(SalesStartDate) 
			And ValueIsFilled(SalesRestrictionDate) 
			And SalesStartDate > SalesRestrictionDate Then
		
			CommonClientServer.MessageToUser(
				NStr("vi = 'Ngày kết thúc bán hàng nhỏ hơn ngày bắt đầu.';
					|ru = 'Дата окончания продаж меньше чем дата начала.';
					|en = 'Sales end date is earlier than the start date.'; fa = 'Sales end date is earlier than the start date.';
					|it = 'La data di fine delle vendite è precedente a quella di inizio.';
					|pl = 'Data zakończenia sprzedaży jest mniejsza niż data początku.';
					|tr = 'Satış bitiş tarihi, başlangıç ​​tarihinden daha önce.'"),
				ThisObject,
				"SalesRestrictionDate",
				,
				Cancel);
		
		EndIf;
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	If IsNew() Then
		InitializeDocument(FillingData);
	EndIf;
EndProcedure

Procedure OnCopy(CopiedObject)
	
	EmployeeResponsible		 = UsersClientServer.CurrentUser();
	ValidityStartDate	 = BegOfDay(CurrentSessionDate());
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Operation = Enums.ProductRangeChangeTransactions.CollectionManagement Then
		
		Stage = Enums.ProductRangeChangeSteps.EmptyRef();
		Phase = Enums.ProductRangePhases.EmptyRef();
		
	Else
		ItemsCollection = Catalogs.ItemsCollections.EmptyRef();
		PurchaseStartDate = Undefined;
		SalesStartDate = Undefined;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

// Parameters:
//    Table - See AccessManagement.AccessValuesSetsTable
Procedure FillAccessValuesSets(Table) Export
	
	// The logic of the restriction is as follows:
	// the object is available if all types of prices are available.
	
	TypesOfPrices = Goods.Unload();
	TypesOfPrices.GroupBy("PriceKind");
	
	For Each TableRow In TypesOfPrices Do
		
		If Not ValueIsFilled(TableRow.PriceKind) Then
			Continue;
		EndIf;
		
		TabRow = Table.Add();
		TabRow.AccessValue = TableRow.PriceKind;
		
	EndDo;
	
	If Table.Count() = 0 Then
		TabRow = Table.Add();
		TabRow.AccessValue = Catalogs.TypesOfPrices.EmptyRef();
	EndIf;
	
EndProcedure

// Initializes the document
//
Procedure InitializeDocument(FillingData = Undefined)
	
	EmployeeResponsible		 = Users.CurrentUser();
	ValidityStartDate	 = BegOfDay(CurrentSessionDate());
	PlanningObject	 = SettingsValueCached.GetDefaultSchedulingObject(PlanningObject);
	
EndProcedure

#EndRegion

#EndIf