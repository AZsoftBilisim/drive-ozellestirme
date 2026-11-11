#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object",						Object);
	AdditionalParameters.Insert("ItemForPlacementName",	"GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization",		True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	// StandardSubsystems.IBUpdate
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	// End StandardSubsystems.IBUpdate
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FormEvents
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	// End StandardSubsystems.FormEvents
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// Standard subsystems.Modificationconfiguration
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	// The end of the standard subsystem.Modificationconfiguration
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// Standard subsystems.Modificationconfiguration
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	// The end of the standard subsystem.Modificationconfiguration
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not ValueIsFilled(Object.MainProductCharacteristic)
		And ItemVariantsAreUsed Then
		
		MessageText = CommonClientServer.FillingErrorText("Field", "FillType", NStr("vi = 'Đặc tính';
																					|ru = 'Характеристика';
																					|en = 'Variant'; fa = 'گونه';
																					|it = 'Caratteristica';
																					|pl = 'Charakterystyka';
																					|tr = 'Varyant'"));
		
		Common.MessageToUser(
			MessageText,,
			"MainProductCharacteristic",
			"Object",
			Cancel);
		
	EndIf;
	
	If Not ValueIsFilled(Object.UnderRepairVariant)
		And FinishedProductBeingRepairedCharacteristicsAreUsed Then
		
		MessageText = CommonClientServer.FillingErrorText("Field", "FillType", NStr("ru = 'Характеристика (ремонтируемое изделие)';
																					|vi = 'Variant (product under R&M)';
																					|en = 'Variant (product under R&M)'; fa = 'گونه (محصول تحت تعمیر و نگهداری)';
																					|it = 'Variant (product under R&M)';
																					|pl = 'Variant (product under R&M)';
																					|tr = '""Nakit (gayri nakdi) birikim kaydında ""Departman"" özniteliğinin doldurulması.'"));
		
		Common.MessageToUser(
			MessageText,,
			"UnderRepairVariant",
			"Object",
			Cancel);
		
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.AfterWrite(ThisForm, Object, WriteParameters);
	// End StandardSubsystems.AttachableCommands
	
	// Standard subsystems.Modificationconfiguration
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	// The end of the standard subsystem.Modificationconfiguration
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	// Standard subsystems.Modificationconfiguration
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	// The end of the standard subsystem.Modificationconfiguration
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If ThisObject.PropertiesParameters.Property(CurrentPage.Name)
			And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
			
			PropertiesExecuteDeferredInitialization();
			PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure ProcessTypeOnChange(Item)
	
	If Not Object.UnderRepairProduct.IsEmpty()
		And Object.ProcessType <> PredefinedValue("Enum.ProductionProcessTypes.PerformRM") Then
		Object.UnderRepairProduct = Undefined;
		Object.UnderRepairVariant = Undefined;
		Object.UnderRepairBatch = Undefined;
		
		FinishedProductBeingRepairedCharacteristicsAreUsed = False;
	EndIf;
	
	SetPrintCommandVisibility(ThisObject, "ProcessType, UnderRepairProduct");
	
EndProcedure

&AtClient
Procedure ProductsOnChange(Item)
	
	ItemVariantsAreUsed = ?(Object.MainProductProducts.IsEmpty(),
		False,
		ItemVariantsAreUsed(Object.MainProductProducts));
	
	SetPrintCommandVisibility(ThisObject, "MainProductProducts");
	
EndProcedure

&AtClient
Procedure UnderRepairProductOnChange(Item)
	
	FinishedProductBeingRepairedCharacteristicsAreUsed = ?(Object.UnderRepairProduct.IsEmpty(),
		False,
		ItemVariantsAreUsed(Object.UnderRepairProduct));
	
	SetPrintCommandVisibility(ThisObject, "UnderRepairProduct");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region StandardSubsystems

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure
// End StandardSubsystems.Properties

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
EndProcedure

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

&AtClient
Procedure ExpenseGroupOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure(CostGroupsClientServer.CostGroupFields());
	FillPropertyValues(FormParameters, Object);
	
	OpenForm(
		"CommonForm.CostGroupForm",
		FormParameters,
		ThisForm,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	ItemVariantsAreUsed = ItemVariantsAreUsed(
		Object.MainProductProducts);
	
	FinishedProductBeingRepairedCharacteristicsAreUsed = ItemVariantsAreUsed(
		Object.UnderRepairProduct);
	
	SetPrintCommandVisibility(ThisObject);
	
EndProcedure

&AtServerNoContext
Function ItemVariantsAreUsed(Products)
	
	Return Catalogs.Products.ItemVariantsAreUsed(Products);
	
EndFunction

&AtClientAtServerNoContext
Procedure SetPrintCommandVisibility(Form, AttributesList = "")
	
	Items = Form.Items;
	Object   = Form.Object;
	
	AttributesList = New Structure(AttributesList);
	Initialize = Not ValueIsFilled(AttributesList);
	
	If Initialize
		Or AttributesList.Property("More") Then
		
		AdditionalAttributesVisibility = False;
		For Each CurrentItem In Items.GroupAdditionalAttributes.ChildItems Do
			If CurrentItem.Visible Then
				AdditionalAttributesVisibility = True;
				Break;
			EndIf;
		EndDo;
		
		Items.GroupPageMore.Visible = AdditionalAttributesVisibility;
		
	EndIf;
	
	If Initialize
		Or AttributesList.Property("InternalSubcontracting") Then
		InternalSubcontracting = False;
		InternalSubcontracting = Object.InternalSubcontracting;
		Items.GroupCompanyPage.Visible = InternalSubcontracting;
	EndIf;
	
	If Not Items.GroupCompanyPage.Visible
		And Not Items.GroupPageMore.Visible Then
		Items.GroupPages.PagesRepresentation = FormPagesRepresentation.None;
	Else
		Items.GroupPages.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
	EndIf;
	
	If Initialize
		Or AttributesList.Property("ProcessType") Then
		Items.GroupRepairedFinishedProduct.Visible = 
			Object.ProcessType = PredefinedValue("Enum.ProductionProcessTypes.PerformRM");
	EndIf;
	
	If Initialize
		Or AttributesList.Property("MainProductProducts") Then
		
		If Form.ItemVariantsAreUsed Then
			Items.Characteristic.Enabled = True;
			Items.Characteristic.InputHint = "";
			Items.Characteristic.AutoMarkIncomplete = True;
		Else
			Items.Characteristic.Enabled = False;
			Items.Characteristic.InputHint = NStr("vi = '<không sử dụng đặc tính>';
													|ru = '<характеристики не используются>';
													|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
													|it = '<le caratteristiche non vengono usate>';
													|pl = '<charakterystyki nie dotyczą>';
													|tr = '<varyantlar kullanılmamaktadır>'");
			Items.Characteristic.AutoMarkIncomplete = False;
		EndIf;
		
	EndIf;
	
	If Initialize
		Or AttributesList.Property("UnderRepairProduct") Then
		
		If Form.FinishedProductBeingRepairedCharacteristicsAreUsed Then
			Items.UnderRepairVariant.Enabled = True;
			Items.UnderRepairVariant.InputHint = "";
			Items.UnderRepairVariant.AutoMarkIncomplete = True;
		Else
			Items.UnderRepairVariant.Enabled = False;
			Items.UnderRepairVariant.InputHint = NStr("vi = '<không sử dụng đặc tính>';
														|ru = '<характеристики не используются>';
														|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
														|it = '<le caratteristiche non vengono usate>';
														|pl = '<charakterystyki nie dotyczą>';
														|tr = '<varyantlar kullanılmamaktadır>'");
			Items.UnderRepairVariant.AutoMarkIncomplete = False;
		EndIf;
		
	EndIf;
	
EndProcedure

#Region StandardSubsystems

#Region Properties

// StandardSubsystems.Properties
&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
	SetPrintCommandVisibility(ThisObject, "More");
	
EndProcedure
// End StandardSubsystems.Properties

#EndRegion

#EndRegion

#EndRegion
