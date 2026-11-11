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

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	If Object.Ref.IsEmpty() Then
		FillInFormDetails();
		CustomizeFormElements();
	EndIf;

	// Subsystem prohibiting the editing of key details of objects.
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	NameFillSelectionList(Items.Description, Object);
	Catalogs.PackagesAndUnitsOfMeasure.DisplayInformationAboutStorageUnit(Object.Owner, Items.Package);

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

	FillInFormDetails();
	CustomizeFormElements();

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

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

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("KitOwner", Object.Owner);
	WriteParameters.Insert("Kit",          Object.Ref);
	WriteParameters.Insert("Main",          Object.Main);
	WriteParameters.Insert("Characteristic",    Object.Characteristic);
	
	Notify("Write_ProductKitConfigurations", WriteParameters, Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ComponentPresentationClick(Item, StandardProcessing)
	StandardProcessing = False;
	ShowValue(Undefined, Object.ProductsOfMainComponent);
EndProcedure

&AtClient
Procedure OwnerOnChange(Item)
	
	FillInFormDetails();
	CustomizeFormElements();
	
	NameFillSelectionList(Items.Description, Object);
	
EndProcedure

&AtClient
Procedure CharacteristicOnChange(Item)
	
	NameFillSelectionList(Items.Description, Object);

EndProcedure

&AtClient
Procedure CharacteristicClearing(Item, StandardProcessing)
	
	NameFillSelectionList(Items.Description, Object);
	
EndProcedure

&AtClient
Procedure NumberOfPackagesOnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", New Structure("Package,Products,MustBeRoundOff",Object.Package, Object.Owner, False));

	BatchProcessingOfTablePartClient.ProcessTSString(Object, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure PackageOnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", New Structure("Package,Products,MustBeRoundOff",Object.Package, Object.Owner, False));

	BatchProcessingOfTablePartClient.ProcessTSString(Object, StructureOfActions, CachedValues);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsProductsOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	Actions = New Structure("
		|CheckCharacteristicsByOwner, FillInCCDTrackingAttribute,
		|CheckFillPackageByOwner, RecalculateNumberOfUnits");
	Actions.CheckCharacteristicsByOwner = CurrentRow.Characteristic;
	Actions.CheckFillPackageByOwner = CurrentRow.Package;
	Actions.FillInCCDTrackingAttribute = New Structure("Products", "TheRecordsAreKeptByCCD");
	Actions.RecalculateNumberOfUnits = New Structure("MustBeRoundOff", False);
	
	Actions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)

	CurrentRow = Items.Goods.CurrentData; 
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", New Structure("MustBeRoundOff", False));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow,StructureOfActions,CachedValues);

EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)

	CurrentRow = Items.Goods.CurrentData; 
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", New Structure("MustBeRoundOff", False));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow,StructureOfActions,CachedValues);

EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	Component = Item.CurrentData;
	If Component <> Undefined Then
		FillInMainComponent(Component.Products, Component.Characteristic, Component.TheRecordsAreKeptByCCD, True);
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
Procedure Fill(Command)

	FillInComponents();

EndProcedure

&AtClient
Procedure InstallTheMainComponent(Command)
	Component = Items.Goods.CurrentData;
	If Component <> Undefined Then
		FillInMainComponent(Component.Products, Component.Characteristic, Component.TheRecordsAreKeptByCCD);
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

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

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
// End StandardSubsystems.AttachableCommands

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

&AtClient
Procedure FillInComponents()

	If Object.Goods.Count() > 0 Then

		Response = Undefined;


		ShowQueryBox(New CallbackDescription("FillInComponentsAfterQuestion", ThisObject), NStr("vi = 'Trước khi điền, phần bảng sẽ bị xóa. Điền?';
																								|ru = 'Перед заполнением табличная часть будет очищена. Заполнить?';
																								|en = 'The table will be cleared. Do you want to continue?'; fa = 'جدول پاک خواهد شد. آیا می‌خواهید ادامه دهید؟';
																								|it = 'Prima della compilazione, la tabella sarà cancellata. Compilare?';
																								|pl = 'Przed wypełnieniem część tabelaryczna zostanie wyczyszczona. Wypełnić?';
																								|tr = 'Tablo bölümü doldurulmadan önce temizlenecektir. Doldur?'"),
						QuestionDialogMode.YesNo,,
						DialogReturnCode.Yes,);
        Return;

	EndIf;

	FillInComponentFragment();
EndProcedure

&AtClient
Procedure FillInComponentsAfterQuestion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    
    If Response <> DialogReturnCode.Yes Then
        Return;
    EndIf; 
    
    Object.Goods.Clear();
    
    
    FillInComponentFragment();

EndProcedure

&AtClient
Procedure FillInComponentFragment()

	ParametersOfSelectionForm = New Structure("Owner", Object.Owner);
	FormParameters = New Structure("Filter", ParametersOfSelectionForm);
	FormParameters.Insert("ChoiceMode", True);
	ComponentElement_ = Undefined;

	OpenForm("Catalog.ProductKitConfigurations.ChoiceForm", FormParameters, ThisForm,,,, New CallbackDescription("FillInComponentsCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure FillInComponentsCompletion(Result, AdditionalParameters) Export
    
    ComponentElement_ = Result;
    
    If Not ValueIsFilled(ComponentElement_) Then
        Return;
    EndIf;
    
    FillInTabularPartForComponent(ComponentElement_);

EndProcedure

&AtServer
Procedure FillInTabularPartForComponent(ComponentElement_)
	
	Query = New Query(
	"SELECT
	|	Goods.Products       AS Products,
	|	Goods.Characteristic     AS Characteristic,
	|	Goods.Package           AS Package,
	|	Goods.NumberOfPackages AS NumberOfPackages,
	|	Goods.CostShare      AS CostShare,
	|	Goods.Count         AS Count
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS Goods
	|WHERE
	|	Goods.Ref = &Ref
	|
	|ORDER BY
	|	Goods.LineNumber
	|");
	Query.SetParameter("Ref", ComponentElement_);
	
	Object.Goods.Load(Query.Execute().Unload());
	
	FillInFormDetails();
	CustomizeFormElements();

EndProcedure

&AtServer
Procedure FillInFormDetails()
	
	ItemVariantsAreUsed = Catalogs.Products.ItemVariantsAreUsed(Object.Owner);
	TheRecordsAreKeptByCCD = TMCommonUse.DefaultValuesForItemDetails(Object.Owner, "KeepRecordsByCCD").KeepRecordsByCCD;
	
	Actions = New Structure("FillInFeatureAttribute, FillInCCDTrackingAttribute");
	Actions.FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	Actions.FillInCCDTrackingAttribute = New Structure("Products", "TheRecordsAreKeptByCCD");
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, Actions);
	
	TheMainComponentIsAccountedForByTheGasTurbineEngine = TMCommonUse.DefaultValuesForItemDetails(Object.ProductsOfMainComponent,
											"KeepRecordsByCCD").KeepRecordsByCCD;
		
	ViewOfTheMainComponent = ProductsClientServer.ProductPresentation(
		Object.ProductsOfMainComponent, Object.MainComponentCharacteristic);
				
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	UseImportedGoods_ = GetFunctionalOption("UseImportedGoods");
	Items.ComponentRequirementGroup.Visible = UseImportedGoods_;
	Items.EmptyComponentGroup.Visible = UseImportedGoods_;
	
	Items.Owner.ReadOnly = ValueIsFilled(Object.Owner) And Not Object.Ref.IsEmpty();
	Items.Characteristic.Enabled = ItemVariantsAreUsed;
	Items.GoodsTheRecordsAreKeptByCCD.Visible = TheRecordsAreKeptByCCD;
	
	If ValueIsFilled(Object.Owner) Then
		If ValueIsFilled(Object.ProductsOfMainComponent) Then
			Page = Items.ComponentViewGroup;
		Else
			If TheRecordsAreKeptByCCD Then
				Page = Items.ComponentRequirementGroup;
			Else
				Page = Items.EmptyComponentGroup;
			EndIf;
		EndIf;
	Else
		Page = Items.GroupNotFilledSet;
	EndIf;
	
	Items.MainComponentGroup.CurrentPage = Page;
	
	If TheRecordsAreKeptByCCD And Not TheMainComponentIsAccountedForByTheGasTurbineEngine Then
		Items.ComponentCommentGroup.CurrentPage = Items.TheCommentGroupWillNotBeAGTD;
	Else
		Items.ComponentCommentGroup.CurrentPage = Items.GroupWithoutComment;
	EndIf;
	
	HintMainComponent = NStr("vi = 'Mục hiện tại là cấu phần chính của bộ đóng gói, theo đó có xác định nước xuất xứ và số tờ khai hải quan';
							|ru = 'Текущая позиция является основным компонентом сборки, по которому определяется страна происхождения и номера ГТД';
							|en = 'The current item is the main assembly component used to determine the country of origin and CCD numbers'; fa = 'The current item is the main assembly component used to determine the country of origin and CCD numbers';
							|it = 'La posizione corrente è il componente principale dell''assieme, che determina il paese di origine e i numeri della polizza doganale di carico';
							|pl = 'Aktualna pozycja jest głównym elementem zespołu, który określa kraj pochodzenia i numer TDC';
							|tr = 'Mevcut durum, menşe ülkesini ve GKB numarasını belirleyen montajın ana bileşenidir'");
	If Not TheRecordsAreKeptByCCD Then
		HintMainComponent = NStr("vi = 'Vị trí hiện tại là thành phần chính của lắp ráp.';
								|ru = 'Текущая позиция является основным компонентом сборки';
								|en = 'The current item is the main component of the assembly'; fa = 'The current item is the main component of the assembly';
								|it = 'Il componente corrente è un componente dell''assieme';
								|pl = 'Bieżąca pozycja jest podstawowym elementem zespołu';
								|tr = 'Mevcut konum, montajın ana bileşenidir'");
	EndIf;
	CommandIsMainComponent = Commands.Find("InstallTheMainComponent");
	CommandIsMainComponent.ToolTip = HintMainComponent;
	
	UseKitPackaging = ?(Not Object.Owner.IsEmpty(), Common.ObjectAttributeValue(Object.Owner, "UsePackages"), False);
	If Not GetFunctionalOption("UseItemPackages")
		Or Not UseKitPackaging Then
		Items.PagesPackagingUnits.CurrentPage = Items.PageUnitOfMeasure;
	Else
		Items.PagesPackagingUnits.CurrentPage = Items.PagePackaging;
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInMainComponent(ComponentProducts, ComponentCharacteristics, CCDAccounting, Delete = False)
	ClearComponent = (ComponentProducts = Object.ProductsOfMainComponent)
		And (ComponentCharacteristics = Object.MainComponentCharacteristic);
	If ClearComponent Then
		Object.ProductsOfMainComponent = Undefined;
		Object.MainComponentCharacteristic = Undefined;
		TheMainComponentIsAccountedForByTheGasTurbineEngine = False;
	ElsIf Not Delete Then
		Object.ProductsOfMainComponent = ComponentProducts;
		Object.MainComponentCharacteristic = ComponentCharacteristics;
		TheMainComponentIsAccountedForByTheGasTurbineEngine = CCDAccounting;
	EndIf;
	ViewOfTheMainComponent = ProductsClientServer.ProductPresentation(
		Object.ProductsOfMainComponent, Object.MainComponentCharacteristic);
		
	Items.MainComponentGroup.CurrentPage = 
		?(ValueIsFilled(Object.ProductsOfMainComponent), Items.ComponentViewGroup,
		?(TheRecordsAreKeptByCCD, Items.ComponentRequirementGroup, Items.EmptyComponentGroup));
	Items.ComponentCommentGroup.CurrentPage =
		?(TheRecordsAreKeptByCCD And Not TheMainComponentIsAccountedForByTheGasTurbineEngine, Items.TheCommentGroupWillNotBeAGTD,
		Items.GroupWithoutComment);
EndProcedure

&AtClientAtServerNoContext
Procedure NameFillSelectionList(Item, Object)
	
	Item.ChoiceList.Clear();
	
	Presentation = TrimAll(Object.Owner);
	If ValueIsFilled(Object.Characteristic) Then
		Presentation = Presentation + " " + TrimAll(Object.Characteristic);
	EndIf;
	
	Item.ChoiceList.Add(Presentation);
	
EndProcedure

#EndRegion

#EndRegion
