

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Object.Type = AccountType.Active Then
		AccountTypePresentation = "1";	
	ElsIf Object.Type = AccountType.Passive Then
		AccountTypePresentation = "2";	
	ElsIf Object.Type = AccountType.ActivePassive Then
		AccountTypePresentation = "3";	
	EndIf;
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	ManagingFormElementsDuringCreation();
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	Items.ExcludeFromExchangeDifferenceCalculationInFunctionalCurrency.Visible = Object.Currency1;
	Items.ExtDimensionTypesQuantitative.Visible = Object.Quantitative;
	Items.ExtDimensionTypesCurrency1.Visible = Object.Currency1;
	
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

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FormEvents.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure Currency1OnChange(Item)
	
	Items.ExcludeFromExchangeDifferenceCalculationInFunctionalCurrency.Visible = Object.Currency1;
	Items.ExtDimensionTypesCurrency1.Visible = Object.Currency1;
	
EndProcedure

&AtClient
Procedure CodeOnChange(Item)
	
	Object.Order = TrimAll(StrReplace(Object.Code, ".", ""));
	
	Object.QuickSelectionCode = TrimAll(StrReplace(Object.Code, ".", ""));
	
EndProcedure

&AtClient
Procedure KindOnChange(Item)
		
	OldAccountType = Object.Type;
	
	If AccountTypePresentation = "1" Then
		Object.Type = AccountType.Active;
	ElsIf AccountTypePresentation = "2" Then
		Object.Type = AccountType.Passive; 
	ElsIf AccountTypePresentation = "3" Then
		Object.Type = AccountType.ActivePassive;
	EndIf;
	
	If OldAccountType <> Object.Type Then
		Modified = True;
	EndIf;

EndProcedure

#EndRegion

#Region TableEventHandlersExtDimensionTypes

&AtClient
Procedure ExtDimensionTypesOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		Item.CurrentData.Currency1       = True;
		Item.CurrentData.Quantitative = True;
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

////////////////////////////////////////////////////////////////////////////////
// SERVICE PROCEDURES AND FUNCTIONS OF BSP

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

&AtClient
Procedure QuantitativeOnChange(Item)
	
	Items.ExtDimensionTypesQuantitative.Visible = Object.Quantitative;
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
    
    LockedAttributes = ObjectAttributesLockClient.Attributes(ThisObject);
    
    If LockedAttributes.Count() > 0 Then
        FormParameters = New Structure;
        FormParameters.Insert("Object", Object.Ref);
        FormParameters.Insert("LockedAttributes", LockedAttributes);
        
        OpenForm("CommonForm.UnlockChartOfAccountsAttributes", FormParameters,
            ThisObject,,,, New CallbackDescription("AfterAttributesToUnlockChoice", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
    Else
        ObjectAttributesLockClient.ShowAllVisibleAttributesUnlockedWarning();
    EndIf;
EndProcedure

&AtClient
Procedure AfterAttributesToUnlockChoice(AttributesToUnlock, Context) Export
    
    If TypeOf(AttributesToUnlock) <> Type("Array") Then
        Return;
    EndIf;
    
    ObjectAttributesLockClient.SetFormItemEnabled(ThisObject,
        AttributesToUnlock);
    
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtServer
Procedure ManagingFormElementsDuringCreation()
	
	Items.ReclassGroup.Visible = Parameters.DisplayTheClassAttribute;
	Items.AccountingByLinesOfBusiness.Visible = Catalogs.LinesOfBusiness.AccountingByDirectionsIsUsed();
	Items.ExcludeFromExchangeDifferenceCalculationInFunctionalCurrency.Visible = Object.Currency1;
	Items.ExtDimensionTypesQuantitative.Visible = Object.Quantitative;
	Items.ExtDimensionTypesCurrency1.Visible = Object.Currency1;
	
	MethodOfAccountingForImproperValues = Common.ObjectAttributeValue(Object.ChartOfAccounts,
		"MethodOfNotOwnedControlledValuesAccounting");
	Items.OffBalance.Visible = Object.OffBalance Or MethodOfAccountingForImproperValues =
		Enums.MethodsOfNotOwnedControlledValuesAccounting.RecordedOnOffBalanceAccounts;
	
EndProcedure

#EndRegion
