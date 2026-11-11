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
	
	RestrictionOfSaveFormats = StrSplit(Parameters.RestrictionOfSaveFormats, ",", False);
	For Each SaveFormat In PrintManagement.SpreadsheetDocumentSaveFormatsSettings() Do
		If Not RestrictionOfSaveFormats.Count()
			Or RestrictionOfSaveFormats.Find(SaveFormat.Extension) <> Undefined Then
				
			SelectedSaveFormats.Add(String(SaveFormat.SpreadsheetDocumentFileType), SaveFormat.Presentation, False, SaveFormat.Picture);
		EndIf;
	EndDo;
	SelectedSaveFormats[0].Check = True; // By default, only the first format from the list is selected.
	
	If SelectedSaveFormats.Count() = 1 Then
		Items.FormatsSelectionGroup.Visible = False;
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "WithoutChoosingFormat");
	ElsIf SelectedSaveFormats.Count() > 1 Then
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "");
	EndIf;

	AttachmentObjects = ObjectsToAttach(Parameters.PrintObjects);
	
	CanBeSaved = Parameters.PrintObjects.Count() > 0;
	If Parameters.PrintObjects.Count() = 1 Then
		HasOpportunityToAttach = AttachmentObjects[0].Check;
	ElsIf CanBeSaved Then
		HasOpportunityToAttach = False;
		For Each ObjectForAttaching In AttachmentObjects Do
			HasOpportunityToAttach = HasOpportunityToAttach Or ObjectForAttaching.Check;
		EndDo;
	Else
		HasOpportunityToAttach = False;
	EndIf;
	
	Items.SelectFileSaveLocation.Visible = Parameters.FileOperationsExtensionAttached 
		Or HasOpportunityToAttach;
		
	Items.SavingOption.Visible = HasOpportunityToAttach;

	If Not HasOpportunityToAttach Then
		Items.FilesSaveDirectory.TitleLocation = FormItemTitleLocation.Top;
	EndIf;
	
	If Parameters.Purpose = "AttachedFiles" Then
		SavingOption = "Join";
		Items.FilesSaveDirectory.Visible = False;
		Title = ?(Parameters.PrintObjects.Count() > 1,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đính kèm vào chứng từ (%1)';
					|ru = 'Присоединить к документам (%1)';
					|en = 'Attach to documents (%1)'; fa = 'Attach to documents (%1)';
					|it = 'Attach to documents (%1)';
					|pl = 'Attach to documents (%1)';
					|tr = 'Belgelere ekle (%1)'"), Parameters.PrintObjects.Count()),
				NStr("vi = 'Đính kèm vào chứng từ';
					|ru = 'Присоединить к документу';
					|en = 'Attach to document'; fa = 'پیوست به سند';
					|it = 'Allega al documento';
					|pl = 'Załącz do dokumentu';
					|tr = 'Belgeye ekle'"));
		AutoTitle = False;
		Items.SaveButton.Title =  NStr("vi = 'Đính kèm';
										|ru = 'Присоединить';
										|en = 'Attach'; fa = 'پیوست کردن';
										|it = 'Attach';
										|pl = 'Attach';
										|tr = 'Ekle'");
	Else
		SavingOption = "SaveToFolder";
		Items.FilesSaveDirectory.Visible = Parameters.FileOperationsExtensionAttached;
	EndIf;
	
	If Parameters.PrintObjects.Count() > 1 Then
		Item = Items.SavingOption.ChoiceList.FindByValue("Join");
		If Item <> Undefined Then
			Item.Presentation = NStr("vi = 'Đính kèm văn bản';
									|ru = 'Присоединить к документам';
									|en = 'Attach to documents'; fa = 'Attach to documents';
									|it = 'Присоединить к документам';
									|pl = 'Attach to documents';
									|tr = 'Belgelere ekle'")
				+ " (" + Format(Parameters.PrintObjects.Count(), "NFD=0;") + ")";
		EndIf;
	EndIf;
	
	IsExternalUserSession = Users.IsExternalUserSession();
	IsMobileClient = Common.IsMobileClient();
	
	If IsMobileClient Then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
		Items.SaveButton.Representation = ButtonRepresentation.Picture;
	EndIf;
	
	Items.Sign.Visible = Not IsMobileClient And Not IsExternalUserSession;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If SelectedSaveFormats.Count() <> 1 Then
		SaveFormatsFromSettings = Settings["SelectedSaveFormats"];
		If SaveFormatsFromSettings <> Undefined Then
			For Each SelectedFormat In SelectedSaveFormats Do 
				FormatFromSettings = SaveFormatsFromSettings.FindByValue(SelectedFormat.Value);
				If FormatFromSettings <> Undefined Then
					SelectedFormat.Check = FormatFromSettings.Check;
				EndIf;
			EndDo;
			Settings.Delete("SelectedSaveFormats");
		EndIf;
	Else
		Settings.Delete("SelectedSaveFormats");
	EndIf;
	
	If Common.IsMobileClient() Then
		Settings["Sign"] = False;
	EndIf;
	
	If Not Items.SavingOption.Visible Then
		Settings["SavingOption"] = "SaveToFolder"; 
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Items.FilesSaveDirectory.Enabled = SavingOption <> "Join";
	
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	If SelectedSaveFormats.Count() = 1 Then
		Settings.Delete("SelectedSaveFormats");
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FolderToSaveFilesStartChoice(Item, ChoiceData, StandardProcessing)

	SelectedFolder = Item.EditText;
	FileSystemClient.SelectDirectory(
		New CallbackDescription("FolderToSaveFilesSelectionCompletion", ThisObject), , SelectedFolder);
	
EndProcedure

// Completion handler that handles selection of the destination directory.
//  See "FileDialog.Show" in Syntax Assistant.
//
&AtClient
Procedure FolderToSaveFilesSelectionCompletion(Folder, AdditionalParameters) Export 
	If Not IsBlankString(Folder) Then 
		SelectedFolder = Folder;
		ClearMessages();
	EndIf;
EndProcedure

&AtClient
Procedure SavingOptionOnChange(Item)
	
	SetSaveLocationPage();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Save(Command)
	
	If Items.FilesSaveDirectory.Visible Then
		If SavingOption = "SaveToFolder" And IsBlankString(SelectedFolder) Then
			CommonClient.MessageToUser(NStr("vi = 'Hãy chỉ ra thư mục.';
											|ru = 'Укажите каталог.';
											|en = 'Choose a directory.'; fa = 'Choose a directory.';
											|it = 'Choose a directory.';
											|pl = 'Choose a directory.';
											|tr = 'Dizin belirtin.'"),, "SelectedFolder");
			Return;
		EndIf;
	EndIf;
		
	SaveFormats = New Array;
	For Each SelectedFormat In SelectedSaveFormats Do
		If SelectedFormat.Check Then
			SaveFormats.Add(SelectedFormat.Value);
		EndIf;
	EndDo;
	
	If SaveFormats.Count() = 0 Then
		ShowMessageBox(,NStr("vi = 'Hãy chỉ định một trong các định dạng được đề xuất.';
							|ru = 'Укажите один из предложенных форматов.';
							|en = 'Choose one of the suggested formats.'; fa = 'Choose one of the suggested formats.';
							|it = 'Choose one of the suggested formats.';
							|pl = 'Choose one of the suggested formats.';
							|tr = 'Önerilen formatlardan birini belirtin.'"));
		Return;
	EndIf;
	
	SelectionResult = New Structure;
	SelectionResult.Insert("PackToArchive", PackToArchive);
	SelectionResult.Insert("SaveFormats", SaveFormats);
	SelectionResult.Insert("SavingOption", SavingOption);
	SelectionResult.Insert("FolderForSaving", SelectedFolder);
	SelectionResult.Insert("TransliterateFilesNames", TransliterateFilesNames);
	SelectionResult.Insert("Sign", Sign);
	
	If SavingOption = "SaveToFolder" Then
		NotifyChoice(SelectionResult);
		Return;
	EndIf;	
	
	ErrorString = "";
	ObjectsToAttach = New Map; 
	For Each ObjectOfAttachment In AttachmentObjects Do
		If Not ObjectOfAttachment.Check Then
			ErrorString = ErrorString + ObjectOfAttachment.Value;
		Else
			ObjectsToAttach.Insert(ObjectOfAttachment.Value, True);
		EndIf;
	EndDo;
	
	SelectionResult.Insert("ObjectsToAttach", ObjectsToAttach);
	
	If IsBlankString(ErrorString) Then
		NotifyChoice(SelectionResult);
		Return;
	EndIf;

	QueryText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Chưa đính kèm tệp vào các chứng từ:
		| %1';
		|ru = 'Файл не будет присоединен к документам:
		| %1';
		|en = 'The file will not be attached to the documents:
		|%1'; fa = 'The file will not be attached to the documents:
		|%1';
		|it = 'The file will not be attached to the documents:
		|%1';
		|pl = 'The file will not be attached to the documents:
		|%1';
		|tr = 'Dosya belgelere eklenmeyecek: 
		| %1'"), ErrorString);
	
	Buttons = New ValueList;
	Buttons.Add("Cancel", NStr("vi = 'Hủy bỏ';
								|ru = 'Отменить';
								|en = 'Cancel'; fa = 'انصراف';
								|it = 'Отменить';
								|pl = 'Cancel';
								|tr = 'İptal et'"));
	Buttons.Add("Continue", NStr("vi = 'Tiếp tục';
								|ru = 'Продолжить';
								|en = 'Continue'; fa = 'ادامه';
								|it = 'Продолжить';
								|pl = 'Continue';
								|tr = 'Devam et'"));
	
	QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
	QuestionParameters.Title = NStr("vi = 'Không đủ quyền để đính kèm tệp';
									|ru = 'Недостаточно прав для присоединения файла';
									|en = 'Insufficient rights to attach the file'; fa = 'Insufficient rights to attach the file';
									|it = 'Insufficient rights to attach the file';
									|pl = 'Insufficient rights to attach the file';
									|tr = 'Dosyayı ekleyebilmek için izinler yetersiz'");
	QuestionParameters.LockWholeInterface = True;
	QuestionParameters.PromptDontAskAgain = False;
	
	CallbackDescription = New CallbackDescription("SaveAfterConfirm", ThisObject, SelectionResult);
	StandardSubsystemsClient.ShowQuestionToUser(CallbackDescription, QueryText, Buttons, QuestionParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetSaveLocationPage()
	
	If Items.FilesSaveDirectory.Visible Then
		Items.FilesSaveDirectory.Enabled = Not SavingOption = "Join";
	EndIf
	
EndProcedure

&AtClient
Procedure SaveAfterConfirm(QuestionResult, SelectionResult) Export
	
	If QuestionResult = Undefined Or QuestionResult.Value = "Cancel" Then
		Close();
		Return;
	EndIf;
	
	NotifyChoice(SelectionResult);
	
EndProcedure

&AtServerNoContext
Function ObjectsToAttach(PrintObjects)
	Result = New ValueList;
	ModuleFilesOperations = Undefined;
	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperations = Common.CommonModule("FilesOperations");
	EndIf;
	
	For Each PrintObject In PrintObjects Do
		CanAttachFiles = False;
		If ModuleFilesOperations <> Undefined Then
			CanAttachFiles = ModuleFilesOperations.CanAttachFilesToObject(PrintObject.Value);
		EndIf;
		Result.Add(PrintObject.Value,, CanAttachFiles); 
	EndDo;
	
	Return Result;
EndFunction

#EndRegion
