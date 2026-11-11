#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject) 
	
	ScenarioDescriptions.Clear();

EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If IsNew() And Not ValueIsFilled(Code) Then
		SetNewCode();
	EndIf;
	
	If DeletionMark Then
		ScenarioDescriptions.Clear();
	EndIf;
	
	If Not (AdditionalProperties.Property("NotRecalculateFullCatalogCode")
		And AdditionalProperties.NotRecalculateFullCatalogCode = True) Then
	
		InstallFullDirectoryCode(ThisObject, 3);
		
	EndIf;

EndProcedure

#EndRegion

#Region Private

Procedure InstallFullDirectoryCode(Object, DigitsCount = 0) Export
	
	If DigitsCount > 0 Then
		Code = Format(Number(Object.Code), "ND=" + DigitsCount + "; NLZ=");
	Else
		Code = Object.Code;
	EndIf;
	
	If Not Object.Parent.IsEmpty() Then
		Object.FullCode = TrimAll(Common.ObjectAttributesValues(Object.Parent, "FullCode").FullCode) + "." + Code;
	Else
		Object.FullCode = Code;
	EndIf;
	
EndProcedure

Procedure OnReadPresentationsAtServer() Export 
	
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	
EndProcedure

#EndRegion

#EndIf