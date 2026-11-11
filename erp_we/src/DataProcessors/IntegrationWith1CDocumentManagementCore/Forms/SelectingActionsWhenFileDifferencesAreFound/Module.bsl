#If Server Or ThinClient Or ThickClientManagedApplication Then

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillPropertyValues(
		ThisObject,
		Parameters,
		"FullPath,
		|DateTimeOnDisk,
		|DateTimeInThe1CDocumentManagement,
		|DiskSize,
		|SizeInThe1CDocumentManagement,
		|Message,
		|Title");
	
	If DateTimeOnDisk > DateTimeInThe1CDocumentManagement Then
		Items.UseExistingOne.DefaultButton = True;
	Else
		Items.TakeFromThe1CDocumentManagement.DefaultButton = True;
	EndIf;
	
	If DateTimeOnDisk = DateTimeInThe1CDocumentManagement Then
		Items.DateTimeOnDisk.Visible = False;
		Items.DateTimeInThe1CDocumentManagement.Visible = False;
	Else
		TimeZone = SessionTimeZone();
		DateTimeOnDisk = ToLocalTime(DateTimeOnDisk, TimeZone);
		DateTimeInThe1CDocumentManagement = ToLocalTime(DateTimeInThe1CDocumentManagement, TimeZone);
	EndIf;
	
	If DiskSize = SizeInThe1CDocumentManagement Then
		Items.DiskSize.Visible = False;
		Items.SizeInThe1CDocumentManagement.Visible = False;
	Else
		PresentationOfSizeOnDisk =
			IntegrationWith1CDocumentManagementCoreClientServer.DetailedSizePresentation(
				DiskSize);
		PresentationOfTheSizeInThe1CDocumentManagement =
			IntegrationWith1CDocumentManagementCoreClientServer.DetailedSizePresentation(
				SizeInThe1CDocumentManagement);
	EndIf;
	
	WindowOptionsKey = Message;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure TakeFromThe1CDocumentManagement(Command)
	
	Close("TakeFromThe1CDocumentManagement");
	
EndProcedure

&AtClient
Procedure UseExistingOne(Command)
	
	Close("UseExistingOne");
	
EndProcedure

&AtClient
Procedure OpenDirectory(Command)
	
	FileSystemClient.OpenExplorer(FullPath);
	
EndProcedure

#EndRegion

#EndIf

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
