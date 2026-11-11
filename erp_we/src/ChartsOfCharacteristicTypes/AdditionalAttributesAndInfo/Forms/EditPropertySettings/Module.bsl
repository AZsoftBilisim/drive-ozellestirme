///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.IsAdditionalInfo Then
		Items.PropertyTypes.CurrentPage = Items.AdditionalInfoItem;
		Title = NStr("vi = 'Thay đổi tùy chỉnh thông tin bổ sung';
					|ru = 'Изменить настройку дополнительного сведения';
					|en = 'Change additional information record settings'; fa = 'Change additional information record settings';
					|it = 'Modificare l''impostazione dell''informazione aggiuntiva';
					|pl = 'Zmień ustawienia informacji dodatkowej';
					|tr = 'Ek bilgi ayarlarını değiştir'");
	Else
		Items.PropertyTypes.CurrentPage = Items.AdditionalAttribute;
	EndIf;
	
	If ValueIsFilled(Parameters.AdditionalValuesOwner) Then
		Items.AttributeKinds.CurrentPage = Items.SharedAttributesValuesKind;
		Items.InfoKinds.CurrentPage  = Items.SharedInfoValuesKind;
		IndependentPropertyWithSharedValuesList = 1;
	Else
		Items.AttributeKinds.CurrentPage = Items.SharedAttributeKind;
		Items.InfoKinds.CurrentPage  = Items.SharedInfoKind;
		CommonProperty = 1;
	EndIf;
	
	Property = Parameters.Property;
	CurrentPropertiesSet = Parameters.CurrentPropertiesSet;
	IsAdditionalInfo = Parameters.IsAdditionalInfo;
	
	Items.IndependentAttributeValuesComment.Title =
		StringFunctionsClientServer.SubstituteParametersToString(Items.IndependentAttributeValuesComment.Title, CurrentPropertiesSet);
	
	Items.SharedAttributesValuesComment.Title =
		StringFunctionsClientServer.SubstituteParametersToString(Items.SharedAttributesValuesComment.Title, CurrentPropertiesSet);
	
	Items.IndependentInfoItemValuesComment.Title =
		StringFunctionsClientServer.SubstituteParametersToString(Items.IndependentInfoItemValuesComment.Title, CurrentPropertiesSet);
	
	Items.SharedInfoValuesComment.Title =
		StringFunctionsClientServer.SubstituteParametersToString(Items.SharedInfoValuesComment.Title, CurrentPropertiesSet);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New CallbackDescription("WriteAndCloseCompletion", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure KindOnChange(Item)
	
	KindOnChangeAtServer(Item.Name);
	
EndProcedure

&AtServer
Procedure KindOnChangeAtServer(TagName)
	
	IndependentPropertyWithSharedValuesList = 0;
	IndependentPropertyWithIndependentValuesList = 0;
	CommonProperty = 0;
	
	ThisObject[Items[TagName].DataPath] = 1;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	WriteAndCloseCompletion();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure WriteAndCloseCompletion(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If IndependentPropertyWithIndependentValuesList = 1 Then
		WriteBeginning();
	Else
		WriteCompletion(Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteBeginning()
	
	ExecutionResult = WriteAtServer();
	
	If ExecutionResult.Status = "Completed2" Then
		OpenProperty = GetFromTempStorage(ExecutionResult.ResultAddress);
		WriteCompletion(OpenProperty);
	Else
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		CallbackOnCompletion = New CallbackDescription("WriteContinued", ThisObject);
		
		TimeConsumingOperationsClient.WaitCompletion(ExecutionResult, CallbackOnCompletion, IdleParameters);
	EndIf;
	
EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure WriteContinued(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
		Return;
	EndIf;
	
	OpenProperty = GetFromTempStorage(Result.ResultAddress);
	
	WriteCompletion(OpenProperty);
EndProcedure

&AtClient
Procedure WriteCompletion(OpenProperty)
	
	Modified = False;
	
	Notify("Write_AdditionalAttributesAndInfo",
		New Structure("Ref", Property), Property);
	
	Notify("Write_AdditionalAttributesAndInfoSets",
		New Structure("Ref", CurrentPropertiesSet), CurrentPropertiesSet);
	
	NotifyChoice(OpenProperty);
	
EndProcedure

&AtServer
Function WriteAtServer()
	
	JobDescription = NStr("vi = 'Thay đổi tùy chỉnh thuộc tính bổ sung';
							|ru = 'Изменение настройки дополнительного свойства';
							|en = 'Change additional property settings'; fa = 'Change additional property settings';
							|it = 'Modifica dell''impostazione dell''informazione aggiuntiva';
							|pl = 'Zmiana ustawień informacji dodatkowej';
							|tr = 'Ek özellik ayarlarını değiştir'");
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Property", Property);
	ProcedureParameters.Insert("CurrentPropertiesSet", CurrentPropertiesSet);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 2;
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	
	Result = TimeConsumingOperations.ExecuteInBackground("ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.ChangePropertySetting",
		ProcedureParameters, ExecutionParameters);
	
	Return Result;
	
EndFunction

#EndRegion
