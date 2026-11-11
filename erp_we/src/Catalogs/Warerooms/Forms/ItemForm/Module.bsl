
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

	OnReadCreateAtServer();	

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
	
	SetAvailability();
	SetFormFunctionalOptionParameters(New Structure("Warehouse, Premise", Object.Owner, Object.Ref));
	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	If Object.CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.CellsBalance
		 And Not GetFunctionalOption("UseItemPackages") Then
   		 NotifyOfDisabledPackaging = True;
	EndIf;

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	InterfaceUpdateIsRequired = False;
	
	For Each RowStructure In BankAccountDetailsCache Do
		If Object[RowStructure.Key] <> RowStructure.Value Then
			InterfaceUpdateIsRequired = True;
			Break;
		EndIf;
	EndDo;
	
	If InterfaceUpdateIsRequired Then
		RefreshInterface();
		
		DetailsCacheStructure = New Structure;
		DetailsCacheStructure.Insert("WarehouseZoneUsage",Object.WarehouseZoneUsage);
		DetailsCacheStructure.Insert("CustomizeBinLocationWarehousing",Object.CustomizeBinLocationWarehousing);
		
		BankAccountDetailsCache = New FixedStructure(DetailsCacheStructure);
	EndIf;
	
	If NotifyOfDisabledPackaging Then
		MessageText = NStr("vi = 'Trong tùy chỉnh kế toán đã ngắt sử dụng bộ đóng gói mặt hàng. Không thể ghi tăng hàng hóa trong kho
		|có cất giữ số dư theo từng ô mà không chỉ ra bộ đóng gói.';
		|ru = 'В настройках учета отключено использование упаковок номенклатуры. Оприходовать товар на склад
		|с хранением остатков в разрезе ячеек без указания упаковок невозможно.';
		|en = 'Item packaging units are disabled in the accounting settings. Specify the units in the goods receipt 
		|because bins management is enabled in the warehouse.'; fa = 'Item packaging units are disabled in the accounting settings. Specify the units in the goods receipt 
		|because bins management is enabled in the warehouse.';
		|it = 'Nelle impostazioni di contabilità, l''uso delle confezioni dell''articolo è disabilitato. È impossibile depositare le merci nel magazzino
		|immagazzinando i residui nelle celle senza specificare le confezioni.';
		|pl = 'W ustawieniach ewidencji wyłączono używanie opakowań towarów. Zarejestrować towar w magazynie
		|z przechowywaniem ostatków w  komórkach bez określenia opakowań nie jest możliwe.';
		|tr = 'Muhasebe ayarlarında ürün paketleme ünitelerinin kullanımı devre dışı bırakıldı. Depo konum takibini kullanan ambara ürün girişi,
		|paketleme ünitesi belirtilmeden mümkün değildir.'");
		ShowMessageBox(, MessageText);
	EndIf;

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

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CustomizeBinLocationWarehousingOnChange(Item)
	
	CustomizeBinLocationWarehousingOnChangeServer();
	
EndProcedure

&AtClient
Procedure CustomizeBinLocationWarehousingStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	WarehouseStore = GeneralPurposeTMServerCall.ObjectAttributeValue(Object.Owner, "WarehouseStore");
	
	ChoiceData = New ValueList;
	ChoiceData.Add(PredefinedValue("Enum.SettingsOfBinLocationWarehousing.DontUse"));
	ChoiceData.Add(PredefinedValue("Enum.SettingsOfBinLocationWarehousing.BinsReferenceAddress"));
	If WarehouseStore <> PredefinedValue("Enum.TypesOfWarehouses.RetailStore") Then
		ChoiceData.Add(PredefinedValue("Enum.SettingsOfBinLocationWarehousing.CellsBalance"));
	EndIf;
	
EndProcedure

&AtClient
Procedure CustomizeBinLocationWarehousingClearing(Item, StandardProcessing)

	StandardProcessing = False;

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
// End StandardSubsystems.AttachableCommands

// Handler for a command created by the mechanism that prohibits editing key details.
//
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)

	If Not Object.Ref.IsEmpty() Then
		OpenForm("Catalog.Warerooms.Form.AttributeUnlocking",,,,,, 
			New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject), 
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
    
    If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
        
        ObjectAttributesLockClient.SetFormItemEnabled(ThisForm, Result);
        
    EndIf;

EndProcedure

&AtClient
Procedure SettingsOfBinLocationWarehouses(Command)
	
	DimensionStructure = New Structure;
	DimensionStructure.Insert("Warehouse", Object.Owner);
	DimensionStructure.Insert("Premise", Object.Ref);
	ArrayOfConstructorParameters = New Array();
	ArrayOfConstructorParameters.Add(DimensionStructure);
	RecordKey = New("InformationRegisterRecordKey.SettingsOfBinLocationWarehouses", ArrayOfConstructorParameters);
	FormParameters = New Structure("Key", RecordKey);
	OpenForm("InformationRegister.SettingsOfBinLocationWarehouses.RecordForm", FormParameters, ThisForm,,);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	SetFormFunctionalOptionParameters(New Structure("Warehouse, Premise", Object.Owner, Object.Ref));
	If ValueIsFilled(Object.Ref) Then
		DetailsCacheStructure = New Structure;
		DetailsCacheStructure.Insert("CustomizeBinLocationWarehousing",Object.CustomizeBinLocationWarehousing);
	Else
		DetailsCacheStructure = New Structure;
		DetailsCacheStructure.Insert("CustomizeBinLocationWarehousing",Undefined);
	EndIf;
	
	BankAccountDetailsCache = New FixedStructure(DetailsCacheStructure);
	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	SetAvailability();
	
EndProcedure

&AtServer
Procedure CustomizeBinLocationWarehousingOnChangeServer()
	
	If Object.CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.DontUse Then
		Object.WarehouseZoneUsage = Enums.UseIsDeterminedInWarerooms.DontUse
	EndIf;
	
	SetAvailability();
	
	If Not (Object.CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.CellsBalance)
		Or Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	Query = New Query();
	Query.SetParameter("Warehouse", Object.Owner);
	Query.SetParameter("Premise", Object.Ref);
	Query.Text = Catalogs.Warehouses.RequestTextForDocumentsThatDependOnUseOfAddressStorage(True);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	Selection.Next();
	If ValueIsFilled(Selection.Date) Then
		RecommendedDate = Selection.Date + 60 * 60 * 24;
		Object.StartDateOfUsingWarehouseBinSystem = Max(CurrentSessionDate(), RecommendedDate);
	Else
		Items.StartDateOfUsingWarehouseBinSystem.ReadOnly = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailability()
	
	WarehouseStore = Common.ObjectAttributeValue(Object.Owner, "WarehouseStore");
	
	Items.WarehouseZoneUsage.Enabled = (Object.CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.CellsBalance
														Or Object.CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.BinsReferenceAddress)
														And (Not WarehouseStore = Enums.TypesOfWarehouses.RetailStore);
	Items.CustomizeBinLocationWarehousing.ReadOnly = Object.CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.CellsBalance
			And Items.CustomizeBinLocationWarehousing.ReadOnly;
	
	If Object.CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.CellsBalance Then
		Items.PagesOfBinLocationWarehouseSettings.CurrentPage = Items.PageHyperlink;
		Items.PagesStartDateOfBinLocationWarehousingOfRemainingGoods.CurrentPage = Items.PageStartDateOfBinLocationWarehousingOfRemainingGoodsDate;
	Else
		Items.PagesOfBinLocationWarehouseSettings.CurrentPage = Items.BlankPage;
		Items.PagesStartDateOfBinLocationWarehousingOfRemainingGoods.CurrentPage = Items.TheAddressStorageStartDatePageIsEmpty;
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
