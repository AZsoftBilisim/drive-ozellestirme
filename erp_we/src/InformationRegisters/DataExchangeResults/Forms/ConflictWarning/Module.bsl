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
	
	Parameters.Property("ObjectWithIssue", ObjectWithIssue);
	Parameters.Property("LongDesc", LongDesc);
	Parameters.Property("WarningType", WarningType);
	Parameters.Property("InfobaseNode", InfobaseNode);
	Parameters.Property("VersionFromOtherApplication", VersionFromOtherApplication);
	Parameters.Property("ThisApplicationVersion", ThisApplicationVersion);
	Parameters.Property("VersionFromOtherApplicationAccepted", VersionFromOtherApplicationAccepted);
	Parameters.Property("OccurrenceDate", OccurrenceDate);
	Parameters.Property("HideWarning", HideWarning);
	Parameters.Property("WarningComment", WarningComment);
	
	HideFromListFlagUpdateRequired = False;
	CommentUpdateRequired = False;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ChangeThePictureOfTheScenery()
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure HideWarningOnChange(Item)
	
	HideFromListFlagUpdateRequired = True;
	
	If HideWarning Then
		
		Items.PictureDecoration.Picture = PictureLib.Information32;
		
	Else
		
		Items.PictureDecoration.Picture = PictureLib.Error32;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ObjectWithIssueClick(Item, StandardProcessing)
	
	HideFromListFlagUpdateRequired = True;
	
EndProcedure

&AtClient
Procedure WarningCommentOnChange(Item)
	
	CommentUpdateRequired = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShowDifferences(Command)
	
	If ThisApplicationVersion = 0
		Or VersionFromOtherApplication = 0 Then
		
		MessageText = NStr("vi = 'Để so sánh, cần có hai phiên bản đối tượng.';
							|ru = 'Для сравнения должно быть две версии объекта.';
							|en = 'There must be two object versions for comparison.'; fa = 'There must be two object versions for comparison.';
							|it = 'Per il confronto devono esserci due versioni dell''oggetto.';
							|pl = 'Do porównania powinno być dwie wersji obiektu.';
							|tr = 'Karşılaştırma için nesnenin iki versiyonu bulunmalıdır.'", CommonClient.DefaultLanguageCode());
		CommonClient.MessageToUser(MessageText);
		Return;
		
	EndIf;
	
	VersionsToCompare = New Array;
	VersionsToCompare.Add(VersionFromOtherApplication);
	VersionsToCompare.Add(ThisApplicationVersion);
	
	OpenVersionComparisonReport(ObjectWithIssue, VersionsToCompare);
	
EndProcedure

&AtClient
Procedure OpenVersionInThisApplication(Command)
	
	If Not ValueIsFilled(ObjectWithIssue)
		 Then
		
		Return;
		
	EndIf;
	
	VersionsToCompare = New Array;
	VersionsToCompare.Add(ThisApplicationVersion);
	
	OpenVersionComparisonReport(ObjectWithIssue, VersionsToCompare);

EndProcedure

&AtClient
Procedure OpenOtherApplicationVersion(Command)
	
	If Not ValueIsFilled(ObjectWithIssue) Then
		
		Return;
		
	EndIf;
	
	VersionsToCompare = New Array;
	VersionsToCompare.Add(VersionFromOtherApplication);
	
	OpenVersionComparisonReport(ObjectWithIssue, VersionsToCompare);
	
EndProcedure

&AtClient
Procedure ReviseConflictResolutionResult(Command)
	
	If VersionFromOtherApplicationAccepted Then
		
		QueryText = NStr("vi = 'Thay thế phiên bản đã nhận từ chương trình khác bằng phiên bản từ chương trình này?';
						|ru = 'Заменить версию, полученную из другой программы, на версию из этой программы?';
						|en = 'Do you want to replace the version from another application with the version from this application?'; fa = 'Do you want to replace the version from another application with the version from this application?';
						|it = 'Sostituire la versione ottenuta da un altro programma con la versione da questo programma?';
						|pl = 'Chcesz zastąpić wersję, uzyskaną z innego programu, wersją z tego programu?';
						|tr = 'Başka bir uygulamadan alınan sürüm bu uygulamanın sürümü ile değiştirilsin mi?'");
		
	Else
		
		QueryText = NStr("vi = 'Thay thế phiên bản chương trình này bằng phiên bản đã nhận từ chương trình khác?';
						|ru = 'Заменить версию этой программы на версию, полученную из другой программы?';
						|en = 'Do you want to replace the version from this application with the version from another application?'; fa = 'Do you want to replace the version from this application with the version from another application?';
						|it = 'Sostituire la versione di questo programma con la versione ottenuta da un altro programma?';
						|pl = 'Chcesz zastąpić wersję, tego programu wersją, uzyskaną z innego programu?';
						|tr = 'Bu uygulamanın bir sürümü başka bir uygulamadan alınan sürümle değiştirilsin mi?'");
		
	EndIf;
	
	CallbackDescription = New CallbackDescription("CompleteTheRevisionOfTheResultOfTheCollision", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure CompleteTheRevisionOfTheResultOfTheCollision(Response, AdditionalParameters) Export
	
	If Response <> DialogReturnCode.Yes Then
		
		Return;
		
	EndIf;
	
	ClearMessages();
	
	ErrorMessage = "";
	AcceptRejectVersionAtServer(ErrorMessage);
	
	If IsBlankString(ErrorMessage) Then
		
		HideWarning = True;
		HideFromListFlagUpdateRequired = True;
		
	Else
		
		ShowMessageBox(Undefined, ErrorMessage);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OK(Command)
	
	BeforeCloseAtServer();
	
	If HideFromListFlagUpdateRequired
		Or CommentUpdateRequired Then
		
		Close(New Structure("TheListNeedsToBeUpdated", True));
		
	Else
		
		Close();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ChangeThePictureOfTheScenery()
	
	If HideWarning Then
		
		Items.PictureDecoration.Picture = PictureLib.Information32;
		
	Else
		
		Items.PictureDecoration.Picture = PictureLib.Error32;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenVersionComparisonReport(Ref, VersionsToCompare)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		
		ModuleObjectsVersioningClient = CommonClient.CommonModule("ObjectsVersioningClient");
		ModuleObjectsVersioningClient.OpenVersionComparisonReport(Ref, VersionsToCompare);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AcceptRejectVersionAtServer(ErrorMessage)
	
	If Not Common.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		
		Return;
		
	EndIf;
	
	ModuleObjectsVersioning = Common.CommonModule("ObjectsVersioning");
	Try
		
		ModuleObjectsVersioning.OnStartUsingNewObjectVersion(ObjectWithIssue, VersionFromOtherApplication);
		
	Except
		
		ObjectPresentation	= ?(Common.RefExists(ObjectWithIssue), ObjectWithIssue, ObjectWithIssue.Metadata());
		ExceptionText			= ErrorProcessing.BriefErrorDescription(ErrorInfo());
		TextTemplate1			= NStr("vi = 'Không thể tiếp nhận phiên bản đối tượng ""%1"" do nguyên nhân:%2 %3.';
										|ru = 'Не удалось принять версию объекта ""%1"" по причине:%2 %3.';
										|en = 'Cannot accept the object version ""%1"" due to:%2 %3.'; fa = 'Cannot accept the object version ""%1"" due to:%2 %3.';
										|it = 'Non è stato possibile accettare la versione dell''oggetto ""%1"" a causa di:%2 %3.';
										|pl = 'Nie udało się zaakceptować wersji obiektu ""%1"" z powodu:%2 %3.';
										|tr = '""%1"" nesnenin versiyonu bu nedenle kabul edilemez:%2 %3.'", Common.DefaultLanguageCode());
		ExceptionText			= StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1, ObjectPresentation, Chars.LF, ExceptionText);
		
		Common.MessageToUser(ExceptionText);
		
	EndTry;
	
EndProcedure

&AtServer
Procedure BeforeCloseAtServer()
	
	If Not Common.SubsystemExists("StandardSubsystems.ObjectsVersioning")
		Or (Not HideFromListFlagUpdateRequired 
			And Not CommentUpdateRequired) Then
		
		Return;
		
	EndIf;
	
	RegisterEntryParameters = New Structure;
	RegisterEntryParameters.Insert("Ref", ObjectWithIssue);
	RegisterEntryParameters.Insert("VersionNumber", VersionFromOtherApplication);
	RegisterEntryParameters.Insert("VersionIgnored", HideWarning);
	RegisterEntryParameters.Insert("Comment", WarningComment);
	
	ModuleObjectsVersioning = Common.CommonModule("ObjectsVersioning");
	ModuleObjectsVersioning.ChangeTheSyncWarning(RegisterEntryParameters, True);
	
EndProcedure

#EndRegion
