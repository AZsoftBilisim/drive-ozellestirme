
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

	If ValueIsFilled(Object.Ref) Then
		
		Object_Attributes = Common.ObjectAttributesValues(Object.Ref, "QuickGoods, FormCommands");
		TableFastGoods = Object_Attributes.QuickGoods.Get();
		If TableFastGoods <> Undefined Then
			QuickGoods.Load(TableFastGoods);
		EndIf;
		
		FormCommandTable = Object_Attributes.FormCommands.Get();
		If FormCommandTable <> Undefined Then
			FormCommands.Load(FormCommandTable);
		EndIf;
		
		QuantityOfQuickGoods = QuickGoods.Count();
		NumberOfFormCommands = FormCommands.Count();
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not ValueIsFilled(Object.Ref) Then
		FillInByDefaultOnClient();
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	For Each TSRow In QuickGoods Do
		If Not ValueIsFilled(TSRow.Key) Then
			TSRow.Key = String(Key.None);
		EndIf;
	EndDo;
	For Each TSRow In FormCommands Do
		If Not ValueIsFilled(TSRow.Key) Then
			TSRow.Key = String(Key.None);
		EndIf;
	EndDo;
	
	CurrentObject.QuickGoods  = New ValueStorage(QuickGoods.Unload());
	CurrentObject.FormCommands = New ValueStorage(FormCommands.Unload());

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ReadingFormCommands"
		And Parameter.Form = UUID Then
		
		FillInByDefaultOnServer(Parameter.AddressInTempStorage);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_KeyboardShortcuts", , Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersQuickGoods

&AtClient
Procedure QuickGoodsProductsOnChange(Item)
	
	CurrentData = Items.QuickGoods.CurrentData;
	CurrentData.Title = ProductsClientServer.ProductPresentation(
				CurrentData.Products,
				CurrentData.Characteristic,
				CurrentData.Package);
	
	CurrentRow = Items.QuickGoods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "QuickGoods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure QuickGoodsCharacteristicOnChange(Item)
	
	CurrentData = Items.QuickGoods.CurrentData;
	CurrentData.Title = ProductsClientServer.ProductPresentation(
				CurrentData.Products,
				CurrentData.Characteristic,
				CurrentData.Package);
	
EndProcedure

&AtClient
Procedure QuickGoodsPackageOnChange(Item)
	
	CurrentData = Items.QuickGoods.CurrentData;
	CurrentData.Title = ProductsClientServer.ProductPresentation(
				CurrentData.Products,
				CurrentData.Characteristic,
				CurrentData.Package);
	
EndProcedure

&AtClient
Procedure QuickGoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.QuickGoodsShortcut = Field Then
		
		StandardProcessing = False;
		ReturnValue = Undefined;
		
		FormOpenParameters = New Structure("Address", AddressInTempStorage());
		
		AdditionalSelectionProcessingOptions = New Structure("RowSelected", RowSelected);
		ChoiceHandler = New CallbackDescription("QuickGoodsSelectionCompletion", ThisObject, AdditionalSelectionProcessingOptions);
		
		OpenForm("Catalog.KeyboardShortcuts.Form.FormSelectKeyCombination",
			FormOpenParameters,
			ThisObject,,,,
			ChoiceHandler,
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure QuickGoodsOnChange(Item)
	QuantityOfQuickGoods = QuickGoods.Count();
EndProcedure

&AtClient
Procedure QuickGoodsAfterDeleteRow(Item)
	QuantityOfQuickGoods = QuickGoods.Count();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCommands

&AtClient
Procedure FormCommandsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.FormCommandsShortcut = Field Then
		
		StandardProcessing = False;
		ReturnValue = Undefined;
		
		FormOpenParameters = New Structure("Address", AddressInTempStorage());
		
		AdditionalSelectionProcessingOptions = New Structure("RowSelected", RowSelected);
		ChoiceHandler = New CallbackDescription("FormCommandsSelectionCompletion", ThisObject, AdditionalSelectionProcessingOptions);
		
		OpenForm("Catalog.KeyboardShortcuts.Form.FormSelectKeyCombination",
			FormOpenParameters,
			ThisObject,,,, 
			ChoiceHandler,
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FillByDefault(Command)
	
	FillInByDefaultOnClient();
	
EndProcedure

&AtClient
Procedure HideAllCommands(Command)
	
	For Each TSRow In FormCommands Do
		TSRow.Hide_2 = False;
	EndDo;
	
EndProcedure

&AtClient
Procedure ShowAllCommands(Command)
	
	For Each TSRow In FormCommands Do
		TSRow.Hide_2 = True;
	EndDo;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "QuickGoodsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "QuickGoods.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
																			 "QuickGoodsCharacteristic",
																		     "QuickGoods.ItemVariantsAreUsed");

EndProcedure

#Region Other

&AtClient
Procedure FillInByDefaultOnClient()
	
	StructureBase = New Structure("ReadingFormCommands");
	FormParameters = New Structure("Basis, AutoTest_2", StructureBase);
	DocumentFormCheckCashRegister = GetForm("Document.CashRegisterReceipt.Form.CWPDocumentForm", FormParameters);
	
	NotificationParameters = New Structure("Form, OwnerForm",
		DocumentFormCheckCashRegister.UUID,
		UUID);
		
	Notify("ReadingFormCommands", NotificationParameters);
	
EndProcedure

&AtServer
Function KeyboardShortcutPresentation(Combination)
	
	Return TMCommonUse.KeyboardShortcutPresentation(Combination, True);
	
EndFunction

&AtServer
Procedure FillInByDefaultOnServer(AddressInTempStorage)
	
	FormCommands.Clear();
	
	FormCommandTable = GetFromTempStorage(AddressInTempStorage);
	For Each FormCommand In FormCommandTable Do
		NewRow = Catalogs.KeyboardShortcuts.NewCommand(FormCommands, FormCommand);
	EndDo;
	
	NumberOfFormCommands = FormCommands.Count();
	
EndProcedure

&AtServer
Function AddressInTempStorage()
	
	DataForTemporaryStorage = New Structure;
	DataForTemporaryStorage.Insert("QuickGoods", QuickGoods.Unload());
	DataForTemporaryStorage.Insert("FormCommands",  FormCommands.Unload());
	
	Return PutToTempStorage(DataForTemporaryStorage, UUID);
	
EndFunction

&AtClient
Procedure ClearKeyboardShortcut(Shortcut)
	
	KeyboardShortcutPresentation = KeyboardShortcutPresentation(Shortcut);
	
	For Each TSRow In QuickGoods Do
		If TSRow.Shortcut = KeyboardShortcutPresentation Then
			TSRow.Key = String(Key.None);
			TSRow.Ctrl = False;
			TSRow.Shift = False;
			TSRow.Alt = False;
			TSRow.Shortcut = "";
		EndIf;
	EndDo;
	For Each TSRow In FormCommands Do
		If TSRow.Shortcut = KeyboardShortcutPresentation Then
			TSRow.Key = String(Key.None);
			TSRow.Ctrl = False;
			TSRow.Shift = False;
			TSRow.Alt = False;
			TSRow.Shortcut = "";
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	For Each TSRow In QuickGoods Do
		If Not ValueIsFilled(TSRow.Products) Then
			
			LineNumber = QuickGoods.IndexOf(TSRow);
			
			CommonClientServer.MessageToUser(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa điền trường ""Mặt hàng"" tại dòng %1';
						|ru = 'Не заполнено поле ""Номенклатура"" в строке %1';
						|en = '""Items"" is required in line %1'; fa = '""Items"" is required in line %1';
						|it = 'Il campo ""articolo"" nella riga %1 non è compilato';
						|pl = 'Nie wypełniono pola ""Produkt"" w wierszu %1';
						|tr = '%1 satırındaki ""Öğe"" alanı doldurulmadı'"),
					LineNumber + 1
				),,
				"QuickGoods["+LineNumber+"].Products",,Cancel);
			
		EndIf;
		If Not ValueIsFilled(TSRow.Characteristic) And TSRow.ItemVariantsAreUsed Then
			
			LineNumber = QuickGoods.IndexOf(TSRow);
			
			CommonClientServer.MessageToUser(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa điền trường ""Đặc tính"" tại dòng %1';
						|ru = 'Не заполнено поле ""Характеристика"" в строке %1';
						|en = '""Variant"" is required in line %1'; fa = '""Variant"" is required in line %1';
						|it = 'Il campo ""Caratteristica"" nella riga %1 non è compilato';
						|pl = 'Nie wypełniono pola ""Charakterystyka"" w wierszu %1';
						|tr = '%1 satırındaki ""Varyant"" alanı doldurulmadı'"),
					LineNumber + 1
				),,
				"QuickGoods["+LineNumber+"].Characteristic",,Cancel);
			
		EndIf;
	EndDo;
	
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

#Region NotificationsHandlers

&AtClient
Procedure FormCommandsSelectionCompletion(Result, AdditionalParameters) Export
	
	RowSelected = AdditionalParameters.RowSelected;
	
	ReturnValue = Result;
	
	If ReturnValue <> Undefined Then
		
		ClearKeyboardShortcut(ReturnValue);
		
		CurrentRow = FormCommands.FindByID(RowSelected);
		CurrentRow.Shortcut = KeyboardShortcutPresentation(ReturnValue);
		
		FillPropertyValues(CurrentRow, ReturnValue);
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure QuickGoodsSelectionCompletion(Result, AdditionalParameters) Export
	
	RowSelected = AdditionalParameters.RowSelected;
	
	ReturnValue = Result;
	
	If ReturnValue <> Undefined Then
		
		ClearKeyboardShortcut(ReturnValue);
		
		CurrentRow = QuickGoods.FindByID(RowSelected);
		CurrentRow.Shortcut = KeyboardShortcutPresentation(ReturnValue);
		
		FillPropertyValues(CurrentRow, ReturnValue);
		Modified = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
