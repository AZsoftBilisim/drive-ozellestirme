
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	MultipleIndication = CommonClientServer.StructureProperty(
								Parameters, "MultipleScopeIndication", False);
	
	ListOfProperties = "LineOfBusiness,"
					+ "ProductionOrder,"
					+ "SalesOrder,"
					+ "Department,"
					+ "BillOfMaterials,"
					+ "Stage,"
					+ "Product,"
					+ "ItemVariantOfProduct,"
					+ "QuantityOfMaterials";
	
	FillPropertyValues(ThisObject, Parameters, ListOfProperties);
	
	UseTheBusinessLine = ValueIsFilled(LineOfBusiness);
	UseAProductionOrder = ValueIsFilled(ProductionOrder);
	UseACustomerOrder = ValueIsFilled(SalesOrder);
	UseADivision = ValueIsFilled(Department);
	
		If ValueIsFilled(SalesOrder) 
			Or ValueIsFilled(ProductionOrder) 
				And TypeOf(ProductionOrder) <> Type("DocumentRef.ProductionOrder2_2")Then
			ReadOnly = True;
			Items.FormOK.Enabled = False;
		Else
			Items.ProductionOrder.TypeRestriction = New TypeDescription("DocumentRef.ProductionOrder2_2");
			Items.UseACustomerOrder.Visible = False;
			Items.SalesOrder.Visible = False;
		EndIf;
	
	If ValueIsFilled(BillOfMaterials) Then
		
		UseTheProduct = True;
		UsageModeProduct = 1;
		ByBillOfMaterials = True;
		UseAStage = ValueIsFilled(Stage);
		
	ElsIf ValueIsFilled(Product) Then
		
		UseTheProduct = True;
		UsageModeProduct = 0;
		
		If ValueIsFilled(ItemVariantOfProduct) Then
			CharacteristicsAreUsedForTheCurrentProduct = True;
			UseTheProductDescription = True;
		Else
			CharacteristicsAreUsedForTheCurrentProduct = WhetherCharacteristicsAreUsedOnServer(Product);
			UseTheProductDescription = False;
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(BillOfMaterials) Or QuantityOfMaterials > 0 Then
		NotifyOfModeChange = True;
	EndIf;
	
	SetVisibilityDependingOnMultipleIndications();
	SetAvailability();

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	QueryText = NStr("vi = 'Dữ liệu bị thay đổi. Đưa các thay đổi vào chứng từ?';
					|ru = 'Данные были изменены. Перенести изменения в документ?';
					|en = 'The data was modified. Migrate the changes to the document?'; fa = 'The data was modified. Migrate the changes to the document?';
					|it = 'I dati sono stati modificati. Trasferire le modifiche nel documento?';
					|pl = 'Dane zostały zmienione. Przenieść zmiany do dokumentu?';
					|tr = 'Veriler değiştirildi. Değişiklikler belgeye aktarılsın mı?'");
	Notification = New CallbackDescription("WriteAndCloseOnClient", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit, QueryText);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseTheBusinessLineOnChange(Item)
	Items.LineOfBusiness.Enabled = UseTheBusinessLine;	
EndProcedure

&AtClient
Procedure UseAProductionOrderOnChange(Item)
	Items.ProductionOrder.Enabled = UseAProductionOrder;
EndProcedure

&AtClient
Procedure UseACustomerOrderOnChange(Item)
	Items.SalesOrder.Enabled = UseACustomerOrder;
EndProcedure

&AtClient
Procedure UseADivisionOnChange(Item)
	Items.Department.Enabled = UseADivision;
EndProcedure

&AtClient
Procedure UseTheProductOnChange(Item)
	
	UseTheProductDescription = False;
	
	SetAvailabilityOfProduct(
		Items, 
		UseTheProduct, 
		UsageModeProduct, 
		UseTheProductDescription,
		CharacteristicsAreUsedForTheCurrentProduct, 
		UseAStage);
	
EndProcedure

&AtClient
Procedure ByBillOfMaterialsOnChange(Item)
	
	If NotifyOfModeChange Then
		
		QueryText = NStr("vi = 'Việc thay đổi vùng hiệu lực sẽ làm xóa 
									|phần bảng ""Tập hợp nguyên vật liệu được thay thế"".
									|Tiếp tục?';
									|ru = 'Изменение области действия приведет к очистке 
									|табличной части ""Набор заменяемых материалов"".
									|Продолжить?';
									|en = 'Changing the scope will clear 
									| the ""Set of substitutes"" table.
									| Continue?'; fa = 'Changing the scope will clear 
									| the ""Set of substitutes"" table.
									| Continue?';
									|it = 'Modifica dell''ambito di applicazione porterà alla cancellazione 
									|della tabella ""Insieme dei materiali da sostituire"".
									|Continuare?';
									|pl = 'Zmiana zakresu działania doprowadzi do oczyszczenia 
									|części tabelarycznej ""Zestaw materiałów zastępczych"".
									|Kontynuować?';
									|tr = 'Alanın değiştirilmesi, ""Değiştirilen Malzeme Kümesi"" 
									|tablo bölümünün temizlenmesine neden olacaktır.
									|Devam edilsin mi?'");
		
		ShowQueryBox(New CallbackDescription("ByBillOfMaterialsOnChangeCompletion", ThisObject), QueryText, QuestionDialogMode.YesNo);
        Return;
		
	EndIf;
	
	AccordingToSpecificationWhenChangingFragment();
	
EndProcedure

&AtClient
Procedure ByBillOfMaterialsOnChangeCompletion(QuestionResult, AdditionalParameters) Export
    
	If QuestionResult = DialogReturnCode.Yes Then
        NotifyOfModeChange = False;
		AccordingToSpecificationWhenChangingFragment();
	Else
		UsageModeProduct = 0;
    EndIf;
    
EndProcedure

&AtClient
Procedure AccordingToSpecificationWhenChangingFragment()
	
    UseTheProductDescription = False;
	
	SetAvailabilityOfProduct(
		Items, 
		UseTheProduct, 
		UsageModeProduct, 
		UseTheProductDescription,
		CharacteristicsAreUsedForTheCurrentProduct, 
		UseAStage);

EndProcedure

&AtClient
Procedure BillOfMaterialsStartChoice(Item, ChoiceData, StandardProcessing)
	
	If NotifyOfModeChange Then
		
		StandardProcessing = False;
		
		QueryText = NStr("vi = 'Thay đổi bảng kê chi tiết các nguồn lực sản xuất sẽ xóa phần bảng ""Nguyên vật liệu"", tiếp tục?';
						|ru = 'Изменение спецификации приведет к очистке табличной части ""Материалы"", продолжить?';
						|en = 'Changing the BOM will clear the ""Materials"" table. Continue?'; fa = 'Changing the BOM will clear the ""Materials"" table. Continue?';
						|it = 'Modifica della specifica porterà alla cancellazione della tabella ""Materiali"", continuare?';
						|pl = 'Zmiana specyfikacji spowoduje wyczyszczenie części tabelarycznej ""Materiały"", kontynuować?';
						|tr = 'Ürün reçetesinin değiştirilmesi, ""Malzemeler"" tablo bölümünün temizlenmesine neden olacaktır, devam edilsin mi?'");
		CallbackDescription = New CallbackDescription("BillOfMaterialsStartChoiceCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ByProductProducedOnChange(Item)
	
	UseTheProductDescription = False;
	
	SetAvailabilityOfProduct(
		Items, 
		UseTheProduct, 
		UsageModeProduct, 
		UseTheProductDescription,
		CharacteristicsAreUsedForTheCurrentProduct, 
		UseAStage);	
	
EndProcedure

&AtClient
Procedure ProductOnChange(Item)
	
	UseTheProductDescription = False;
	
	If ValueIsFilled(Product) Then
		CharacteristicsAreUsedForTheCurrentProduct = WhetherCharacteristicsAreUsedOnServer(Product);
	Else
		CharacteristicsAreUsedForTheCurrentProduct = False;
	EndIf;
	
	Items.UseTheProductDescription.Enabled = CharacteristicsAreUsedForTheCurrentProduct;
	Items.ItemVariantOfProduct.Enabled = UseTheProductDescription;
	
EndProcedure

&AtClient
Procedure UseTheProductDescriptionOnChange(Item)
	Items.ItemVariantOfProduct.Enabled = UseTheProductDescription;
EndProcedure

&AtClient
Procedure UseAStageOnChange(Item)
	Items.Stage.Enabled = UseAStage;	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OkCommand(Command)
	
	If Modified Then
		CompleteEditing();
	Else
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	Modified = False;
	
	Close();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function EditingResultOnServer()
	
	Result = New Structure;
	
	Result.Insert("LineOfBusiness", ?(ValueIsFilled(LineOfBusiness) And UseTheBusinessLine,
		LineOfBusiness, Catalogs.LinesOfBusiness.EmptyRef()));
		
	Result.Insert("ProductionOrder", ?(ValueIsFilled(ProductionOrder) And UseAProductionOrder,
		ProductionOrder, Undefined));
		
	Result.Insert("SalesOrder", ?(ValueIsFilled(SalesOrder) And UseACustomerOrder,
		SalesOrder, Documents.SalesOrder.EmptyRef()));
		
	Result.Insert("Department", ?(ValueIsFilled(Department) And UseADivision,
		Department, Catalogs.BusinessStructure.EmptyRef()));
		
	Result.Insert("BillOfMaterials", ?(ValueIsFilled(BillOfMaterials) And UseTheProduct And UsageModeProduct = 1,
		BillOfMaterials, Catalogs.BillsOfMaterials.EmptyRef()));
		
	Result.Insert("Stage", ?(ValueIsFilled(Stage) And UseAStage And UseTheProduct And UsageModeProduct = 1,
		Stage, Catalogs.ProductionStages.EmptyRef()));
		
	Result.Insert("Product", ?(ValueIsFilled(Product) And UseTheProduct And UsageModeProduct = 0,
		Product, Catalogs.Products.EmptyRef()));
		
	Result.Insert("ItemVariantOfProduct", 
		?(ValueIsFilled(ItemVariantOfProduct) And UseTheProductDescription And UseTheProduct And UsageModeProduct = 0,
		ItemVariantOfProduct,
		Catalogs.ItemsCharacteristics.EmptyRef()));
		
	Result.Insert("MultipleIndication", MultipleIndication);
		
	Return Result;
	
EndFunction

&AtClient
Procedure CompleteEditing()
	
	Cancel = False;
	
	// Checking the fill-in
	ClearMessages();
	
	If UseTheBusinessLine And Not ValueIsFilled(LineOfBusiness) Then
		ErrorText = NStr("vi = 'Chưa điền trường ""Lĩnh vực hoạt động""';
						|ru = 'Поле ""Направление деятельности"" не заполнено';
						|en = '""Line of business"" is required'; fa = '""Line of business"" is required';
						|it = 'Campo ""Settore di attività"" non compilato';
						|pl = 'Pole ""Rodzaj działalności"" nie zostało wypełnione';
						|tr = '""İş Kolu"" alanı doldurulmadı'");
		CommonClient.MessageToUser(ErrorText, , "LineOfBusiness", , Cancel);
	EndIf;
	
	If UseAProductionOrder And Not ValueIsFilled(ProductionOrder) Then
		ErrorText = NStr("vi = 'Trường ""Lệnh sản xuất"" không được điền';
						|ru = 'Поле ""Заказ на производство"" не заполнено';
						|en = '""Production order"" is required'; fa = '""Production order"" is required';
						|it = 'Campo ""Ordine di produzione"" non è compilato';
						|pl = 'Pole ""Zlecenie produkcyjne"" nie jest wypełnione';
						|tr = '""Üretim Emri"" alanı doldurulmadı'");
		CommonClient.MessageToUser(ErrorText, , "ProductionOrder", , Cancel);
	EndIf;
	
	If UseACustomerOrder And Not ValueIsFilled(SalesOrder) Then
		ErrorText = NStr("vi = 'Trường ""Đơn đặt hàng"" không được điền';
						|ru = 'Поле ""Заказ клиента"" не заполнено';
						|en = '""Sales order"" is required'; fa = '""Sales order"" is required';
						|it = 'Campo ""Ordine del cliente"" non è compilato';
						|pl = 'Pole ""Zamówienie klienta"" nie jest wypełnione';
						|tr = '""Satış Siparişi"" alanı doldurulmadı'");
		CommonClient.MessageToUser(ErrorText, , "SalesOrder", , Cancel);
	EndIf;
	
	If UseADivision And Not ValueIsFilled(Department) Then
		ErrorText = NStr("vi = 'Chưa điền trường ""Bộ phận""';
						|ru = 'Поле ""Подразделение"" не заполнено';
						|en = '""Business unit"" is required'; fa = '""Business unit"" is required';
						|it = 'Il campo ""Reparto"" non è compilato';
						|pl = 'Nie wypełniono pola ""Dział""';
						|tr = '""Departman"" alanı doldurulmadı'");
		CommonClient.MessageToUser(ErrorText, , "Department", , Cancel);
	EndIf;
	
	If UseTheProduct And UsageModeProduct = 1 And Not ValueIsFilled(BillOfMaterials) Then	
		ErrorText = NStr("vi = 'Trường ""Bảng kê chi tiết các nguồn lực sản xuất"" trống';
						|ru = 'Поле ""Спецификация"" не заполнено';
						|en = '""Bill of materials"" is required'; fa = '""Bill of materials"" is required';
						|it = 'Il campo ""Specifica"" non è compilato';
						|pl = 'Pole ""Specyfikacja"" nie jest wypełnione';
						|tr = '""Ürün Reçetesi"" alanı doldurulmadı'");
		CommonClient.MessageToUser(ErrorText, , "BillOfMaterials", , Cancel);
	EndIf;
	
	If UseAStage And Not ValueIsFilled(Stage) Then
		ErrorText = NStr("vi = 'Chưa điền trường ""Công đoạn""';
						|ru = 'Поле ""Этап"" не заполнено';
						|en = '""Stage"" is required'; fa = '""Stage"" is required';
						|it = 'Il campo ""Fase"" non è compilato';
						|pl = 'Nie wypłeniono pola ""Этап""';
						|tr = '""Aşama"" alanı doldurulmadı'");
		CommonClient.MessageToUser(ErrorText, , "Stage", , Cancel);
	EndIf;
	
	If UseTheProduct And UsageModeProduct = 0 And Not ValueIsFilled(Product) Then
		ErrorText = NStr("vi = 'Chưa điền trường ""Mặt hàng""';
						|ru = 'Поле ""Номенклатура"" не заполнено';
						|en = '""Product"" is not filled in'; fa = '""Product"" is not filled in';
						|it = 'Il campo ""Articolo"" non è compilato';
						|pl = 'Nie wypełniono pola ""Номенклатура""';
						|tr = '""Ürün"" alanı doldurulmadı'");
		CommonClient.MessageToUser(ErrorText, , "Product", , Cancel);
	EndIf;
	
	If UseTheProductDescription And Not ValueIsFilled(ItemVariantOfProduct) Then
		ErrorText = NStr("vi = 'Chưa điền trường ""Đặc tính""';
						|ru = 'Поле ""Характеристика"" не заполнено';
						|en = '""Variant"" is not filled in'; fa = '""Variant"" is not filled in';
						|it = 'Il campo ""Caratteristica"" non è compilato';
						|pl = 'Pole ""Charakterystyka"" nie jest wypełnione';
						|tr = '""Varyant"" alanı doldurulmadı'");
		CommonClient.MessageToUser(ErrorText, , "ItemVariantOfProduct", , Cancel);
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	Modified = False;
	
	ChoiceStructure = New Structure();
	ChoiceStructure.Insert("CurrentOperation1", "ScopeSelection_");
	ChoiceStructure.Insert("SelectionValue", EditingResultOnServer());
	
	NotifyChoice(ChoiceStructure);
	
EndProcedure

&AtServer
Procedure SetAvailability()
	
	Items.LineOfBusiness.Enabled = UseTheBusinessLine;
	Items.ProductionOrder.Enabled = UseAProductionOrder;
	Items.SalesOrder.Enabled = UseACustomerOrder;
	Items.Department.Enabled = UseADivision;
	
	SetAvailabilityOfProduct(
		Items, 
		UseTheProduct, 
		UsageModeProduct, 
		UseTheProductDescription,
		CharacteristicsAreUsedForTheCurrentProduct, 
		UseAStage);	
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityOfProduct(
			Items,
			AvailabilityFlag,
			AvailabilityMode,
			FlagCharacteristicsAreAvailable,
			UsageCharacteristics,
			UseAStage)
	
	AvailabilitySpecification = AvailabilityFlag And (AvailabilityMode = 1);
	ProductAvailability = AvailabilityFlag And (AvailabilityMode = 0);   
	
	Items.ByBillOfMaterials.Enabled = AvailabilityFlag;	
	Items.ByProductProduced.Enabled = AvailabilityFlag;	
	
	Items.BillOfMaterials.Enabled = AvailabilitySpecification;
	Items.SpecificationLabel.Enabled = AvailabilitySpecification;
	
	Items.UseAStage.Enabled = AvailabilitySpecification;
	Items.Stage.Enabled = AvailabilitySpecification And UseAStage;
	
	Items.Product.Enabled = ProductAvailability;
	Items.TheProductIsTheInscription.Enabled = ProductAvailability;
	
	Items.UseTheProductDescription.Enabled = ProductAvailability And UsageCharacteristics;
	Items.ItemVariantOfProduct.Enabled = FlagCharacteristicsAreAvailable And UsageCharacteristics;
	
EndProcedure	

&AtServerNoContext
Function WhetherCharacteristicsAreUsedOnServer(Products)
	
	UseVariants = Common.ObjectAttributeValue(Products, "UseVariants");
	
	If UseVariants = Enums.ItemVariantsUsageOptions.SpecialForItems 
		Or UseVariants = Enums.ItemVariantsUsageOptions.CommonForItemKind
		Or UseVariants = Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind
		Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

&AtClient
Procedure WriteAndCloseOnClient(Result, AdditionalParameters) Export 
	
	CompleteEditing();
	
EndProcedure

&AtClient
Procedure BillOfMaterialsStartChoiceCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		NotifyOfModeChange = False;
		OpenForm("Catalog.BillsOfMaterials.ChoiceForm",, Items.BillOfMaterials);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityDependingOnMultipleIndications()
	
	If Not MultipleIndication Then
		Return;
	EndIf;
	
	ItemsNames = New Array;
	ItemsNames.Add("GroupLineOfBusiness");
	ItemsNames.Add("DepartmentGroup");
	ItemsNames.Add("CustomerOrderGroup");
	ItemsNames.Add("ProductionOrderGroup");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemsNames, "Visible", False);

EndProcedure

#EndRegion
