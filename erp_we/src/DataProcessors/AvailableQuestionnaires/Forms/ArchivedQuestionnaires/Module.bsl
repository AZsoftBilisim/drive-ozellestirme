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
	
	SetConditionalAppearance();
	
	If Parameters.Respondent <> Undefined And Not Parameters.Respondent.IsEmpty() Then
		Object.Respondent = Parameters.Respondent;
	Else
		SetRespondentAccordingToCurrentExternalUser();
	EndIf;
	SetDynamicListParametersOfQuestionnairesTree();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompletedSurveysValueChoice(Item, Value, StandardProcessing)
	
	CurrentData = Items.CompletedSurveys.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Key",CurrentData.Ref);
	ParametersStructure.Insert("FillingFormOnly",True);
	ParametersStructure.Insert("ReadOnly",True);
	
	OpenForm("Document.Questionnaire.ObjectForm", ParametersStructure,Item);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetDynamicListParametersOfQuestionnairesTree()
	
	RespondentParameter = CompletedSurveys.Parameters.AvailableParameters.Items.Find("Respondent");
	If RespondentParameter <> Undefined Then
		CompletedSurveys.Parameters.SetParameterValue(RespondentParameter.Parameter, Object.Respondent);
	EndIf;
	
EndProcedure 

&AtServer
Procedure SetRespondentAccordingToCurrentExternalUser()
	
	CurrentUser = Users.AuthorizedUser();
	If TypeOf(CurrentUser) <> Type("CatalogRef.ExternalUsers") Then 
		Object.Respondent = CurrentUser;
	Else	
		Object.Respondent = ExternalUsers.GetExternalUserAuthorizationObject(CurrentUser);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "CompletedSurveys.FillingDate", Items.FillingDate.Name);
	
EndProcedure

#EndRegion
