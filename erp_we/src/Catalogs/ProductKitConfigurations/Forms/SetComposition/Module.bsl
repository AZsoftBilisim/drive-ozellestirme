#Region Variables

&AtClient
Var CachedValues;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Object.Ref.IsEmpty() Then
		FillInFormDetails();
		CustomizeFormElements();
	EndIf;

	// Subsystem prohibiting the editing of key details of objects.
	ObjectAttributesLock.LockAttributes(ThisForm);

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	FillInFormDetails();
	CustomizeFormElements();

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	WriteParameters.Insert("KitOwner", Object.Owner);
	WriteParameters.Insert("Kit", Object.Ref);
	WriteParameters.Insert("Main", Object.Main);
	WriteParameters.Insert("Characteristic", Object.Characteristic);

	Notify("Write_ProductKitConfigurations", WriteParameters, Object.Ref);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillInFormDetails();
	CustomizeFormElements();

	// Subsystem prohibiting the editing of key details of objects.
	ObjectAttributesLock.LockAttributes(ThisForm);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ComponentPresentationClick(Item, StandardProcessing)
	StandardProcessing = False;
	ShowValue(Undefined, Object.ProductsOfMainComponent);
EndProcedure

&AtClient
Procedure PresentationOptionInPrintFormsOnChange(Item)
	
	SetsClient.ChangeVisibilityOfSettingsRestrictionWarning(ThisForm);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsProductsOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	Actions = New Structure("
		|CheckCharacteristicsByOwner,
		|CheckFillPackageByOwner, RecalculateNumberOfUnits");
	Actions.CheckCharacteristicsByOwner = CurrentRow.Characteristic;
	Actions.CheckFillPackageByOwner = CurrentRow.Package;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)

	CurrentRow = Items.Goods.CurrentData; 
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow,StructureOfActions,CachedValues);

EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)

	CurrentRow = Items.Goods.CurrentData; 
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow,StructureOfActions,CachedValues);

EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	Component = Item.CurrentData;
	If Component <> Undefined Then
		FillInMainComponent(Component.Products, Component.Characteristic);
	EndIf;
EndProcedure

#EndRegion

#Region EventHandlers

// Handler for a command created by the mechanism that prohibits editing key details.
//
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm);
	
EndProcedure

&AtClient
Procedure InstallTheMainComponent(Command)
	Component = Items.Goods.CurrentData;
	If Component <> Undefined Then
		FillInMainComponent(Component.Products, Component.Characteristic);
	Else
		ShowMessageBox(, NStr("vi = 'Chưa thiết lập bảng kê chi tiết chính. Để thiết lập bảng kê chi tiết chính, cần chọn dòng trong danh sách bảng kê chi tiết.';
								|ru = 'Основная комплектующая не установлена. Для установки основной комплектующей необходимо выбрать строку в списке комплектующих.';
								|en = 'The main component is not installed. To install the main component you need to select a line in the list of components.'; fa = 'The main component is not installed. To install the main component you need to select a line in the list of components.';
								|it = 'Il componente principale non è installato. Per installare il componente principale, è necessario selezionare una riga nell''elenco dei componenti.';
								|pl = 'Główny komponent nie jest zainstalowany. Aby zainstalować główny komponent, musisz wybrać wiersz na liście komponentów.';
								|tr = 'Ana bileşen ayarlanmış değildir. Ana bileşeni ayarlamak için, bileşenler listesinden bir satır seçilmeli.'"));
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)

	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);

EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export

	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);

EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()

	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);

EndProcedure
// StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

	//

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);

EndProcedure

#Region Other

&AtServer
Procedure FillInFormDetails()
	
	If Not ValueIsFilled(Object.Ref) Then
		Object.Owner           = Parameters.Filter.Owner;
		Object.Characteristic     = Parameters.Filter.Characteristic;
		
		Query = New Query(
		"SELECT
		|	Products.ProductKind.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
		|	Products.ProductKind.SetPricingOption AS SetPricingOption
		|FROM
		|	Catalog.Products AS Products
		|WHERE
		|	Products.Ref = &Products");
		
		Query.SetParameter("Products", Object.Owner);
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		If Selection.Next() Then
			FillPropertyValues(Object, Selection);
		EndIf;
		
	EndIf;
	
	Title = String(Object.Owner)
	          + ": "
	          + NStr("vi = 'Thành phần bộ đóng gói';
					|ru = 'Состав набора';
					|en = 'Set content'; fa = 'محتوای مجموعه';
					|it = 'Composizione del set';
					|pl = 'Skład zestawu';
					|tr = 'Set kapsamı'")
	          + ?(Not ValueIsFilled(Object.Ref), " (" + NStr("vi = 'Tạo';
															|ru = 'Создание';
															|en = 'Create'; fa = 'ایجاد';
															|it = 'Creazione';
															|pl = 'Tworzenie';
															|tr = 'Oluşturma'") + ")", "");
	
	ItemVariantsAreUsed = Catalogs.Products.ItemVariantsAreUsed(Object.Owner);
	
	Actions = New Structure("FillInFeatureAttribute");
	Actions.FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, Actions);
	
	ViewOfTheMainComponent = ProductsClientServer.ProductPresentation(
		Object.ProductsOfMainComponent, Object.MainComponentCharacteristic);
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	PriceDistributionOption = "DistributedProportionallyToPrices";
	
	If Object.SetPricingOption = Enums.SetPriceCalculationOptions.CaclulatesFromComponentPrices
		Or Not ValueIsFilled(Object.SetPricingOption) Then
		
		PricingOption = 0;
		
	Else
		
		PricingOption = 1;
		
		If Object.SetPricingOption = Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares Then
			
			PriceDistributionOption = "DistributedProportionallyToShares";
			
		Else
			
			PriceDistributionOption = "DistributedProportionallyToPrices";
			
		EndIf;
		
	EndIf;
	
	Items.GroupSetPriceRight.ReadOnly = (PricingOption = 0);
	
	If Object.SetPricingOption = Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares
		And PricingOption = 1 Then
		Items.GoodsCostShare.AutoMarkIncomplete = True;
		Items.GoodsCostShare.Visible = True;
	Else
		Items.GoodsCostShare.AutoMarkIncomplete = False;
		Items.GoodsCostShare.Visible = False;
	EndIf;
	
	If ValueIsFilled(Object.Owner) Then
		TheRecordsAreKeptByCCD = TMCommonUse.DefaultValuesForItemDetails(Object.Owner, "KeepRecordsByCCD").KeepRecordsByCCD;
	Else
		TheRecordsAreKeptByCCD = False;
	EndIf;
	
	HintMainComponent = NStr("vi = 'Mục hiện tại là cấu phần chính của bộ đóng gói, theo đó có xác định nước xuất xứ và số tờ khai hải quan';
							|ru = 'Текущая позиция является основным компонентом сборки, по которому определяется страна происхождения и номера ГТД';
							|en = 'The current item is the main assembly component used to determine the country of origin and CCD numbers'; fa = 'The current item is the main assembly component used to determine the country of origin and CCD numbers';
							|it = 'La posizione corrente è il componente principale dell''assieme, che determina il paese di origine e i numeri della polizza doganale di carico';
							|pl = 'Aktualna pozycja jest głównym elementem zespołu, który określa kraj pochodzenia i numer TDC';
							|tr = 'Mevcut durum, menşe ülkesini ve GKB numarasını belirleyen montajın ana bileşenidir'");
	If Not TheRecordsAreKeptByCCD Then
		HintMainComponent = NStr("vi = 'Vị trí hiện tại là thành phần chính của lắp ráp';
								|ru = 'Текущая позиция является основным компонентом сборки';
								|en = 'The current item is the main component of the assembly'; fa = 'The current item is the main component of the assembly';
								|it = 'Il componente corrente è un componente dell''assieme';
								|pl = 'Bieżąca pozycja jest podstawowym elementem zespołu';
								|tr = 'Mevcut konum, montajın ana bileşenidir'");
	EndIf;
	CommandIsMainComponent = Commands.Find("InstallTheMainComponent");
	CommandIsMainComponent.ToolTip = HintMainComponent;
	
	Items.GroupWarningSets.Visible = 
		(Object.PresentationOptionInPrintForms = Enums.OptionsOfSetPresentationInPrintForms.OnlySet
		Or PricingOption = 1);
	
EndProcedure

&AtClient
Procedure FillInMainComponent(ComponentProducts, ComponentCharacteristics)
	
	Object.ProductsOfMainComponent = ComponentProducts;
	Object.MainComponentCharacteristic = ComponentCharacteristics;
	
	ViewOfTheMainComponent = ProductsClientServer.ProductPresentation(
	Object.ProductsOfMainComponent, Object.MainComponentCharacteristic);
	
EndProcedure

&AtClient
Procedure PricingOptionOnChange(Item)
	
	Items.GroupSetPriceRight.ReadOnly = (PricingOption = 0);
	
	If PricingOption = 0 Then
		Object.SetPricingOption = PredefinedValue("Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices");
		Items.GoodsCostShare.Visible = False;
		PriceDistributionOption = "DistributedProportionallyToPrices";
	Else
		If PriceDistributionOption = "DistributedProportionallyToPrices" Then
			Object.SetPricingOption = PredefinedValue("Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices");
		ElsIf PriceDistributionOption = "DistributedProportionallyToShares" Then
			Object.SetPricingOption = PredefinedValue("Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares");
		EndIf;
	EndIf;
	
	SetsClient.ChangeVisibilityOfSettingsRestrictionWarning(ThisForm);
	
EndProcedure

&AtClient
Procedure PriceDistributionOptionOnChange(Item)
	
	If PricingOption = 0 Then
		Object.SetPricingOption = PredefinedValue("Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices");
	Else
		If PriceDistributionOption = "DistributedProportionallyToPrices" Then
			Object.SetPricingOption = PredefinedValue("Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices");
		ElsIf PriceDistributionOption = "DistributedProportionallyToShares" Then
			Object.SetPricingOption = PredefinedValue("Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares");
		EndIf;
	EndIf;
	
	If Object.SetPricingOption = PredefinedValue("Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares")
		And PricingOption = 1 Then
		Items.GoodsCostShare.AutoMarkIncomplete = True;
		Items.GoodsCostShare.Visible = True;
	Else
		Items.GoodsCostShare.AutoMarkIncomplete = False;
		Items.GoodsCostShare.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnChange(Item)
	
	If Object.Goods.Count() = 1 Then
		Component = Object.Goods[0];
		If Component <> Undefined Then
			FillInMainComponent(Component.Products, Component.Characteristic);
		EndIf;
	Else
		
		Filter = New Structure;
		Filter.Insert("Products", Object.ProductsOfMainComponent);
		Filter.Insert("Characteristic", Object.MainComponentCharacteristic);
		FoundRows = Object.Goods.FindRows(Filter);
		If FoundRows.Count() = 0 And Object.Goods.Count() > 0 Then
			
			Component = Object.Goods[0];
			If Component <> Undefined Then
				FillInMainComponent(Component.Products, Component.Characteristic);
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	If Object.Goods.Count() = 1 Then
		Component = Object.Goods[0];
		If Component <> Undefined Then
			FillInMainComponent(Component.Products, Component.Characteristic);
		EndIf;
	EndIf;
	
	If Object.Goods.Count() = 0 Then
		FillInMainComponent(Undefined, Undefined);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
