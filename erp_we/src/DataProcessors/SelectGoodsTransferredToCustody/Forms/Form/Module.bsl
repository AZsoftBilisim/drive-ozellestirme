
#Region Variables

&AtClient
Var ClosingInProgress Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Parameters.Owner) Then
		Raise NStr("vi = 'Chỉ có thể mở bộ xử lý từ chứng từ.';
					|ru = 'Предусмотрено открытие обработки только из документов.';
					|en = 'Data processor can be opened only from documents.'; fa = 'Data processor can be opened only from documents.';
					|it = 'Viene fornita l''apertura dell''elaborazione solo dalle forme dei documenti';
					|pl = 'Przewidziano otwarcie przetwarzania tylko z dokumentów.';
					|tr = 'Yalnızca belgelerden işlem açmak için provizyon sağlanmıştır.'");
	EndIf;
	
	FillPropertyValues(Object, Parameters);
	
	Parameters.Property("Ref", Ref);
	Parameters.Property("ObjectManager", ObjectManager);
	Parameters.Property("BusinessOperation", BusinessOperation);
	Parameters.Property("CollapseGTDNumbers", CollapseGTDNumbers);
	Parameters.Property("AddressOfGoodsInvoiceInVault", AddressOfGoodsInvoiceInVault);
	Parameters.Property("UseTraceableImportedGoodsAccounting", UseTraceableImportedGoodsAccounting);
	Parameters.Property("TheCommissionAgentDoesNotKeepRecordsOnTheRNPT", TheCommissionAgentDoesNotKeepRecordsOnTheRNPT);
	
	SetConditionalAppearance();
	
	If Object.ByPhysicalCountResults Then
		Items.GoodsLeftToSelect.ReadOnly = False;
		Items.GoodsLeftToSelect.Title = NStr("vi = 'Số dư(Thực tế)';
											|ru = 'Остаток(Факт)';
											|en = 'Actual balance'; fa = 'مانده واقعی';
											|it = 'Saldo (Effettivo)';
											|pl = 'Actual balance';
											|tr = 'Bakiye(Gerçek)'");
		Items.GoodsCountBalance.Title = NStr("vi = 'Số dư(Kế toán)';
											|ru = 'Остаток(Учет)';
											|en = 'Book balance'; fa = 'Book balance';
											|it = 'Saldo (Contabilità)';
											|pl = 'Book balance';
											|tr = 'Bakiye(Muhasebe)'");
	EndIf;
	
	Parameters.Property("Title", Title);
	AutoTitle = Not ValueIsFilled(Title);
	
	FillInProductsTable_();
	
	CreateInformationLabelSelections();
	
	GenerateTitle();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit
		And Modified Then
		
		Cancel = True;
		WarningText = NStr("vi = 'Đã thay đổi dữ liệu. Tất cả thay đổi sẽ bị mất.';
							|ru = 'Данные были изменены. Все изменения будут потеряны.';
							|en = 'All changes made to the data will be lost.'; fa = 'All changes made to the data will be lost.';
							|it = 'I dati sono stati modificati. Tutte le modifiche verranno perse.';
							|pl = 'Dane zostały zmienione. Wszystkie zmiany zostaną utracone.';
							|tr = 'Veri değişti. Tüm değişiklikler kaybolacak.'");
		
		Return;
		
	EndIf;
	
	If MoveToDocument
		Or ClosingInProgress
		Or Not GoodsAreSelected Then
		
		Return;
		
	Else
		Cancel = True;
		
		QueryText       = NStr("vi = 'Chưa chuyển hàng hóa được chọn vào chứng từ. Chuyển?';
								|ru = 'Подобранные товары не перенесены в документ. Перенести?';
								|en = 'Picked items are not added to the document. Do you want to add them?'; fa = 'Picked items are not added to the document. Do you want to add them?';
								|it = 'La merce selezionata non è stata trasferita nel documento. Trasferire?';
								|pl = 'Wybrane wiersze pozycji nie zostały przeniesione do dokumentu. Przenieść?';
								|tr = 'Seçili ürünler belgeye aktarılmadı. Aktarılsın mı?'");
		CallbackDescription = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNoCancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	ElsIf QuestionResult = DialogReturnCode.Yes Then
		
		If AllowResultsToBeTransferredToDocument() Then
			MoveToDocument = True;
			ClosingInProgress = True;
			
			Close();
		EndIf;
		
		Return;
		
	EndIf;
	
	ClosingInProgress = True;
	
	Close();
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	If MoveToDocument Then
		Structure = New Structure("GoodsAddressInStorage", GoodsAddressInStorage());
		
		NotifyChoice(Structure);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsCheckOnChange(Item)
	
	Modified = True;
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData.Check Then
		CurrentData.QuantityIsSelected = CurrentData.CountBalance;
	Else
		CurrentData.QuantityIsSelected = CurrentData.QuantityInInvoice;
	EndIf;
	
	CalculateNumberInRow(Object.Goods, CurrentData, GoodsAreSelected);
	
EndProcedure

&AtClient
Procedure GoodsQuantityIsSelectedOnChange(Item)
	
	Modified = True;
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentData.Check = CurrentData.QuantityIsSelected > 0 Or Object.ByPhysicalCountResults;
	
	CalculateNumberInRow(Object.Goods, CurrentData, GoodsAreSelected);
	
EndProcedure

&AtClient
Procedure GoodsLeftToSelectOnChange(Item)
	
	Modified = True;
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentData.QuantityIsSelected = CurrentData.CountBalance - CurrentData.LeftToSelect;
	CurrentData.Check = CurrentData.QuantityIsSelected > 0 Or Object.ByPhysicalCountResults;
	
	CalculateNumberInRow(Object.Goods, CurrentData, GoodsAreSelected);
	
EndProcedure
#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	ClearMessages();
	
	If AllowResultsToBeTransferredToDocument() Then
		MoveToDocument = True;
		
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectAllCommand(Command)
	
	MarkEverythingOnServer();
	
EndProcedure

&AtClient
Procedure ClearMark(Command)
	
	UncheckServer();
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	FillInProductsTable_();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Setting the conditional design for the 'Quantity Selected' element of the 'Products' tabular part.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsQuantityIsSelected.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Check");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ByPhysicalCountResults");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Setting the conditional design for the 'NomerGTD' element of the 'Products' tabular part.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumber.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CollapseGTDNumbers");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	If ValueIsFilled(Object.Contract)
		And Not CollapseGTDNumbers
		And Common.ObjectAttributeValue(Object.Contract, "ContractType") = Enums.ContractTypes.WithConsignee
		And BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent Then
		
		AccountingForTraceableGoodsLocalization.EstablishConditionalAppearanceOfAccountingOnGTDVDocumentsOfCommissionAgent(ThisObject);
		
	Else
		
		ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject);
		AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject);
		
	EndIf;
	
	// Fully selected lines are highlighted in gray
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Goods.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.QuantityInInvoice");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.Goods.CountBalance");

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.LeftToSelect");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);
	
	// The changed lines are highlighted in blue
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsQuantityIsSelected.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.QuantityInInvoice");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("Object.Goods.QuantityIsSelected");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
EndProcedure

&AtServer
Procedure FillInProductsTable_()
	
	Var CachedValues;
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.CompanyGoods) Then
		
		Object.Goods.Clear();
		
		Return;
		
	Else
		
		If ValueIsFilled(ObjectManager) Then
			
			DocumentObjectManager = Common.ObjectManagerByFullName(ObjectManager);
			Handler      = DocumentObjectManager.ActionHandler(BusinessOperation);
			
			QueryText = Handler.QueryTextGoodsTransferred();
			
		Else
			QueryText = DataProcessors.SelectGoodsTransferredToCustody.QueryTextGoodsTransferred();
		EndIf;
		
	EndIf;
	
	If CollapseGTDNumbers Then
		
		FieldsToDelete__ = New Array;
		FieldsToDelete__.Add("CCDNumber");
		FieldsToDelete__.Add("OriginCountry");
		
		QueryText = RequestSchemes.RemoveFieldsFromRequest(QueryText, FieldsToDelete__);
		
	EndIf;
	
	PeriodDate_ = EndOfDay(CurrentSessionDate());
	Period      = New Boundary(PeriodDate_, BoundaryType.Including);
	
	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("Period",      Period);
	Query.SetParameter("Recorder", Ref);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Contract",     Object.Contract);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("TheCommissionAgentDoesNotKeepRecordsOnTheRNPT", CollapseGTDNumbers);
	
	If ValueIsFilled(AddressOfGoodsInvoiceInVault) Then
		Goods = GetFromTempStorage(AddressOfGoodsInvoiceInVault); // ValueTable
		Query.SetParameter("Goods", Goods);
	EndIf;
	
	Object.Goods.Load(Query.Execute().Unload());
	
	FillInProductTypeAttribute_  = New Structure("Products", "ItemsType");
	FillInCCDTrackingAttribute = New Structure("Products", "TheRecordsAreKeptByCCD");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActions.Insert("FillInCCDTrackingAttribute", FillInCCDTrackingAttribute);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues)
	
EndProcedure

&AtServer
Procedure CreateInformationLabelSelections()
	
	Filters = New Array;
	Filters.Add(Object.Organization);
	Filters.Add(Object.Owner);
	Filters.Add(Object.Contract);
	
	If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.WriteOffShortagesAtConsignorSExpense") 
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.WriteOffShortagesAtDepositorSExpense")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.WriteOffOfShippedGoods") Then
		Filters.Add(NStr("vi = 'Hàng hóa của doanh nghiệp';
						|ru = 'Собственный товар';
						|en = 'Own goods'; fa = 'کالای خودی';
						|it = 'Merce Propria';
						|pl = 'Towar własny';
						|tr = 'Yerel ürün'"));
	EndIf;
	
	FiltersPresentation = StrConcat(Filters, ", ");
	
	InformationLabelSelections = NStr("vi = 'Lọc theo: %Filters%.';
										|ru = 'Отбор по: %Filters%.';
										|en = 'Filter by: %Filters%.'; fa = 'Filter by: %Filters%.';
										|it = 'Filtro per: %Filters%.';
										|pl = 'Filtr według: %Filters%.';
										|tr = 'Filtre: %Filters%.'");
	InformationLabelSelections = StrReplace(InformationLabelSelections, "%Filters%", FiltersPresentation);
	
EndProcedure

&AtServer
Procedure GenerateTitle()
	
	If AutoTitle
		And ValueIsFilled(Object.Contract) Then
		
		ContractType = Common.ObjectAttributeValue(Object.Contract, "ContractType");
		If ContractType = Enums.ContractTypes.WithConsignee Then
			
			AutoTitle = False;
			Title = NStr("vi = 'Chọn hàng hóa đã chuyển giao đi ký gửi';
						|ru = 'Подбор товаров, переданных на комиссию';
						|en = 'Pick consignment sales stock'; fa = 'انتخاب موجودی فروش امانی';
						|it = 'Selezionare le merci consegnate in base al contratto di commissione';
						|pl = 'Wybór towarów, przekazanych do komisu';
						|tr = 'Komisyona transfer edilen ürünlerin seçimi'");
			
		ElsIf ContractType = Enums.ContractTypes.TransferToTolling2_5 Then
			
			AutoTitle = False;
			Title = NStr("vi = 'Chọn hàng hóa đã chuyển giao đi gia công';
						|ru = 'Подбор товаров, переданных переработчику';
						|en = 'Pick goods transferred to subcontractor'; fa = 'Pick goods transferred to subcontractor';
						|it = 'Selezione articoli trasferiti all''elaboratore';
						|pl = 'Wybór towarów przekazanych przetwórcy';
						|tr = 'Fason üreticiye transfer edilen ürünlerin seçimi'");
			
		EndIf;
		
	EndIf;
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "GoodsCCDNumber");
	
EndProcedure


&AtServer
Function AllowResultsToBeTransferredToDocument()
	
	Return CheckFilling();
	
EndFunction

&AtServer
Function GoodsAddressInStorage()
	
	Filter = New Structure("Check", True);
	SelectedGoodItems      = Object.Goods.Unload(Filter);
	
	Return PutToTempStorage(SelectedGoodItems, UUID);
	
EndFunction

&AtClientAtServerNoContext
Procedure CalculateNumberInRow(Goods, CurrentData, FormModified)
	
	CurrentData.LeftToSelect = CurrentData.CountBalance - CurrentData.QuantityIsSelected;
	
	Filter = New Structure("Check", True);
	MarkedLines_ = Goods.FindRows(Filter);
	
	GoodsAreSelected = MarkedLines_.Count() > 0;
	
EndProcedure

&AtServer
Procedure MarkEverythingOnServer()
	
	Modified = True;
	
	For Each RowOfGoods In Object.Goods Do
		RowOfGoods.QuantityIsSelected = RowOfGoods.CountBalance;
		RowOfGoods.Check = True;
		
		CalculateNumberInRow(Object.Goods, RowOfGoods, GoodsAreSelected);
	EndDo;
	
EndProcedure

&AtServer
Procedure UncheckServer()
	
	For Each RowOfGoods In Object.Goods Do
		RowOfGoods.Check = False;
		RowOfGoods.QuantityIsSelected = RowOfGoods.QuantityInInvoice;
		
		CalculateNumberInRow(Object.Goods, RowOfGoods, GoodsAreSelected);
	EndDo;
	
EndProcedure

#EndRegion

#Region Initialize

ClosingInProgress = False;

#EndRegion
