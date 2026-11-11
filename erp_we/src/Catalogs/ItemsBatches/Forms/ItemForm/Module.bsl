
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("ExpirationDate_") Then
		ExpirationDate_ = Parameters.ExpirationDate_;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// Handler of the "Properties" mechanism
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	TMPropertyManagement.CheckBlankProperties(ThisForm, Object);
	
	If Not ValueIsFilled(Object.ProductKind) Then
		Items.ProductKind.ReadOnly = False;
		Return;
	EndIf;
	
	Items.ProductKind.ReadOnly = True;
	SetSettingsByTemplate();
	ShelfLifeUnitOfMeasure = PolicySettings.ShelfLifeUnitOfMeasure;
	
	ObjectAttributeStructure = New FixedStructure(TMCommonUse.StructureWithMetadataObjectProperties(
				Metadata.Catalogs.ItemsBatches));
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	If ValueIsFilled(Object.ItemsBatchForPricing) Then
		NotifyChanged(Object.ItemsBatchForPricing);
	EndIf;

	AlertStructure = New Structure(ObjectAttributeStructure);
	
	FillPropertyValues(AlertStructure, Object);
	
	Notify("Write_ItemsBatches", AlertStructure, Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProductKindOnChange(Item)
	
	SetSettingsByTemplate();
	
EndProcedure

&AtClient
Procedure ProductionDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ProductsClientServer.RecalculateSeriesDate(Object.ProductionDate);
	
	If ValueIsFilled(ShelfLifeUnitOfMeasure) Then
		Object.ValidUntil_ = ProductsClientServer.ValidUntilDateOfProduction(Object.ProductionDate, ExpirationDate_, ShelfLifeUnitOfMeasure);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductionDateStartChoice(Item, ChoiceData, StandardProcessing)
	
	CallbackDescription = New CallbackDescription("ProductionDateStartChoiceCompletion", ThisObject);
	ProductsClient.ProductionDateStartChoice(Object, CallbackDescription, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ProductionDateStartChoiceCompletion(Result, AdditionalParameters = Undefined) Export
	
	ProductsClientServer.RecalculateSeriesDate(Object.ProductionDate);
	
	If ValueIsFilled(ExpirationDate_) And ValueIsFilled(ShelfLifeUnitOfMeasure) Then
		Object.ValidUntil_ = ProductsClientServer.ValidUntilDateOfProduction(Object.ProductionDate, ExpirationDate_, ShelfLifeUnitOfMeasure);
	EndIf;
	
EndProcedure

&AtClient
Procedure ValidUntil_OnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ProductsClientServer.RecalculateSeriesDate(Object.ValidUntil_);
	
EndProcedure

&AtClient
Procedure ValidUntil_StartChoice(Item, ChoiceData, StandardProcessing)
	
	ParameterNames = "ValidUntil_, ProductionDate, DateFormat, UseProductionDate, ShelfLifeUnitOfMeasure";
	FormParameters = New Structure(ParameterNames);
	
	FillPropertyValues(FormParameters, Object);
	
	FormParameters.DateFormat                    = Items.ValidUntil_.EditFormat;
	FormParameters.UseProductionDate  = Items.ProductionDate.Visible;
	FormParameters.ShelfLifeUnitOfMeasure = PolicySettings.ShelfLifeUnitOfMeasure;
	
	ProductsClient.ExpirationDateStartOfSelection(Object, FormParameters, Undefined,
		StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure GenerateNumber(Command)
	GenerateNumberOnServer();
EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.Properties
&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure
// End StandardSubsystems.Properties

#Region Other

&AtServer
Procedure SetSettingsByTemplate()
	
	DebugMode = TMCommonUse.DebugMode();
	
	PolicySettings = New FixedStructure(Catalogs.ItemKinds.SeriesUseSettings(Object.ProductKind));
		
	For Each LongDesc In PolicySettings.DescriptionsOfUseOfSeriesProps Do
		
		Items[LongDesc.AttributeName].Visible = LongDesc.Use;
		
		If Not IsBlankString(LongDesc.Format) Then
			Items[LongDesc.AttributeName].Format               = LongDesc.Format;
			Items[LongDesc.AttributeName].EditFormat = LongDesc.Format;
		EndIf;
		
	EndDo;
		
	
	YouCanChangeNumber = DebugMode
						Or Not Items.RFIDTID.Visible
						Or Not ((ValueIsFilled(Object.RFIDTID)
									Or ValueIsFilled(Object.RFIDEPC))
								And Not Object.RFIDTagIsCorruptedAndCannotBeRead);
	
	Items.Number.ReadOnly = Not YouCanChangeNumber;
	
	Items.RFIDTID.ReadOnly = Not DebugMode;
	Items.RFIDUser.ReadOnly = Not DebugMode;
	Items.RFIDEPC.ReadOnly = Not DebugMode;
	Items.RFIDTagIsCorruptedAndCannotBeRead.ReadOnly = Not DebugMode;
		
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtServer
Procedure GenerateNumberOnServer()
	
	MaximumNumberFromCatalog = Catalogs.ItemsBatches.CalculateMaximumSeriesNumber(Object.ProductKind);
	MaximumNumberFromCatalog = MaximumNumberFromCatalog + 1;
	Object.Number                   = Format(MaximumNumberFromCatalog, "ND=8; NLZ=; NG=");
	
EndProcedure

#EndRegion

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
	If Item.Name = "sh_ShamsiInput_ProductionDate" Then
		ProductionDateOnChange(Items.ProductionDate);
	ElsIf Item.Name = "sh_ShamsiInput_ValidUntil_" Then
		ValidUntil_OnChange(Items.ValidUntil_);
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
