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
	
	CheckParameters = Catalogs.ExtensionsVersions.DynamicallyChangedExtensions();
	CheckParameters.Insert("DataBaseConfigurationChangedDynamically", DataBaseConfigurationChangedDynamically());
	
	NewPatchesCount = 0;
	If CheckParameters.Corrections <> Undefined And CheckParameters.Corrections.NewItemsList.Count() > 0 Then
		StorageAddress = PutToTempStorage(Undefined, UUID);
		MethodParameters = New Array;
		MethodParameters.Add(StorageAddress);
		MethodParameters.Add(CheckParameters.Corrections.NewItemsList);
		BackgroundJob = ConfigurationExtensions.ExecuteBackgroundJobWithDatabaseExtensions(
			"ConfigurationUpdate.NewPatchesDetails1",
			MethodParameters);
		BackgroundJob.WaitForExecutionCompletion(Undefined);
		
		NewPatchesDetails = GetFromTempStorage(StorageAddress);
		NewPatchesCount = CheckParameters.Corrections.NewItemsList.Count();
	EndIf;
	
	SetMainText(CheckParameters, NewPatchesCount);
	SetVisibilityAvailability(ThisObject);
	
	WithASchedule = True;
	If CheckParameters.Corrections = Undefined
		Or CheckParameters.Corrections.Added2 = 0 Then
		Items.ScheduleGroup.Visible = False;
		WithASchedule = False;
	Else
		FillInTheFormDisplaySchedule();
	EndIf;
	
	Var_Key = "";
	If CheckParameters.DataBaseConfigurationChangedDynamically Then
		Var_Key = "Configuration";
	EndIf;
	If CheckParameters.Corrections <> Undefined Then
		Var_Key = Var_Key + "Corrections";
	EndIf;
	If CheckParameters.Extensions <> Undefined Then
		Var_Key = Var_Key + "Extensions";
	EndIf;
	If WithASchedule Then
		Var_Key = Var_Key + "Schedule";
	EndIf;
	
	StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, Var_Key);
	
	RestartTime = Common.CommonSettingsStorageLoad(
		"UserCommonSettings", 
		"AppRestartTimeForApplyPatches",,,
		UserName());
	
	If Not ValueIsFilled(RestartTime) Then
		RestartTime = Date(1, 1, 1, 23, 00, 00);
	EndIf;

	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	If Not Exit Then
		SaveSchedule();
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	
	Document = New TextDocument;
	Document.SetText(NewPatchesDetails);
	Document.Show(NStr("vi = 'Các bản sửa lỗi mới';
						|ru = 'Новые исправления (патчи)';
						|en = 'New patches'; fa = 'New patches';
						|it = 'Новые исправления (патчи)';
						|pl = 'New patches';
						|tr = 'Yeni düzeltmeler (yamalar)'"));
EndProcedure

&AtClient
Procedure OptionRestartOnChange(Item)
	SetVisibilityAvailability(ThisObject);
EndProcedure

&AtClient
Procedure OptionScheduleOnChange(Item)
	SetVisibilityAvailability(ThisObject);
EndProcedure

&AtClient
Procedure OptionRemindTomorrowOnChange(Item)
	SetVisibilityAvailability(ThisObject);
EndProcedure

&AtClient
Procedure ScheduleClick(Item, StandardProcessing)
	StandardProcessing = False;
	CompletionHandler = New CallbackDescription("ScheduleClickCompletion", ThisObject);
	List = New ValueList;
	List.Add("Once", NStr("vi = 'một lần một ngày';
							|ru = 'один раз в день';
							|en = 'once a day'; fa = 'once a day';
							|it = 'una volta al giorno';
							|pl = 'raz dziennie';
							|tr = 'günde bir defa'"));
	List.Add("Twice", NStr("vi = 'hai lần một ngày';
							|ru = 'два раза в день';
							|en = 'twice a day'; fa = 'twice a day';
							|it = 'due volte al giorno';
							|pl = 'dwa razy dziennie';
							|tr = 'günde iki defa'"));
	List.Add("OtherInterval", NStr("vi = 'khoảng thời gian khác...';
									|ru = 'другой интервал...';
									|en = 'another interval…'; fa = 'another interval…';
									|it = 'un altro intervallo...';
									|pl = 'inny interwał...';
									|tr = 'başka aralık...'"));
	
	ShowChooseFromMenu(CompletionHandler, List, Items.Schedule);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExecuteAction(Command)
	If PossibleAction = 0 Then
		SaveSchedule();
		StandardSubsystemsClient.SkipExitConfirmation();
		Exit(True, True);
	ElsIf PossibleAction = 1 Then
		DoScheduleRestart();
	ElsIf PossibleAction = 2 Then
		StandardSubsystemsClient.DisableScheduledRestart();
		RemindMeTomorrow();
		Close();
	EndIf;
EndProcedure

&AtClient
Procedure DontRemindAgain(Command)
	DontRemindAgainAtServer();
	Close();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure DontRemindAgainAtServer()
	Common.CommonSettingsStorageSave("UserCommonSettings",
		"ShowInstalledApplicationUpdatesWarning",
		False);
EndProcedure

&AtClient
Procedure RemindMeTomorrow()
	RemindTomorrowOnServer();
EndProcedure

&AtServerNoContext
Procedure RemindTomorrowOnServer()
	
	Common.SystemSettingsStorageSave("DynamicUpdateControl",
		"DateRemindTomorrow", BegOfDay(CurrentSessionDate()) + 60*60*24);
	
EndProcedure

&AtClient
Procedure ScheduleClickCompletion(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Value = "Once" Or Result.Value = "Twice" Then
		SchedulePresentation = Result;
		ScheduleChanged = True;
		CurrentSchedule.Id = Result.Value;
		CurrentSchedule.Presentation = Result.Presentation;
		CurrentSchedule.Schedule = StandardSchedule[Result.Value];
		Return;
	EndIf;
	
	CompletionsHandler = New CallbackDescription("ScheduleClickAfterSelectingAnArbitrarySchedule", ThisObject);
	ScheduleDialog1 = New ScheduledJobDialog(New JobSchedule);
	ScheduleDialog1.Show(CompletionsHandler);
EndProcedure

&AtClient
Procedure ScheduleClickAfterSelectingAnArbitrarySchedule(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	ScheduleChanged = True;
	SchedulePresentation = Result;
	CurrentSchedule.Id = "OtherInterval";
	CurrentSchedule.Presentation = String(Result);
	CurrentSchedule.Schedule = Result;
	
EndProcedure

&AtServer
Procedure SaveSchedule()
	If Not ScheduleChanged Then
		Return;
	EndIf;
	
	Common.SystemSettingsStorageSave("DynamicUpdateControl", "PatchCheckSchedule", CurrentSchedule);
EndProcedure

&AtServer
Procedure FillInTheFormDisplaySchedule()
	
	CurrentSchedule = Common.SystemSettingsStorageLoad("DynamicUpdateControl", "PatchCheckSchedule");
	If TypeOf(CurrentSchedule) <> Type("Structure") Then
		CurrentSchedule = New Structure;
		CurrentSchedule.Insert("Id");
		CurrentSchedule.Insert("Presentation");
		CurrentSchedule.Insert("Schedule");
		CurrentSchedule.Insert("LastAlert");
		SchedulePresentation = NStr("vi = 'một lần một ngày';
									|ru = 'один раз в день';
									|en = 'once a day'; fa = 'once a day';
									|it = 'una volta al giorno';
									|pl = 'raz dziennie';
									|tr = 'günde bir defa'");
	Else
		SchedulePresentation = CurrentSchedule.Presentation;
	EndIf;
	
	OnceADay = New JobSchedule;
	OnceADay.DaysRepeatPeriod = 1;
	TwiceADay = New JobSchedule;
	TwiceADay.DaysRepeatPeriod = 1;
	
	FirstRun = New JobSchedule;
	FirstRun.BeginTime = Date(01,01,01,09,00,00);
	TwiceADay.DetailedDailySchedules.Add(FirstRun);
	
	SecondLaunch = New JobSchedule;
	SecondLaunch.BeginTime = Date(01,01,01,15,00,00);
	TwiceADay.DetailedDailySchedules.Add(SecondLaunch);
	
	StandardSchedule = New Structure;
	StandardSchedule.Insert("Once", OnceADay);
	StandardSchedule.Insert("Twice", TwiceADay);
	
EndProcedure

&AtServer
Procedure SetMainText(CheckParameters, NewPatchesCount)
	
	ShouldOutputDetails = False;

	If NewPatchesCount > 5 Then
		PatchesCountToDisplay = 5;
	Else
		PatchesCountToDisplay = NewPatchesCount;
		ShouldOutputDetails = True;
	EndIf;
	
	DetailsOfPatches = NewPatchesDetails;
	BriefDescriptionsOfPatches = New Array;
	For PatchNumber = 1 To PatchesCountToDisplay Do
		CountOfCharacters = StrFind(DetailsOfPatches, Chars.LF);
		CountOfCharacters = ?(CountOfCharacters = 0, StrLen(DetailsOfPatches), CountOfCharacters);
		ShortDescription = TrimAll(Left(DetailsOfPatches, CountOfCharacters));
		DetailsOfPatches = TrimAll(Mid(DetailsOfPatches, CountOfCharacters));
		IsDetailsShortened = False;
		If StrLen(ShortDescription) > 150 Then
			ShortDescription = Left(ShortDescription, 151);
			CountOfCharacters = StrFind(ShortDescription, " ", SearchDirection.FromEnd);
			ShortDescription = Left(ShortDescription, CountOfCharacters);
			ShortDescription = ShortDescription + "...";
			IsDetailsShortened = True;
			ShouldOutputDetails = True;
		EndIf;
		
		StartOfNextPatch = StrFind(DetailsOfPatches, "EF_");
		
		If StartOfNextPatch <> 0 Then 
			DetailsOfPatches = Mid(DetailsOfPatches, StartOfNextPatch);
			If Not IsDetailsShortened And StartOfNextPatch > 1 Then
				ShortDescription = ShortDescription + "...";
				ShouldOutputDetails = True;
			EndIf;
		Else
			MultiLineDetails = ?(StrFind(DetailsOfPatches, Chars.LF) = 0, False, True);
			If Not IsDetailsShortened And MultiLineDetails Then
				ShortDescription = ShortDescription + "...";
				ShouldOutputDetails = True;
			EndIf;
		EndIf;
		BriefDescriptionsOfPatches.Add(TrimAll(ShortDescription));
	EndDo;
	
	BriefDescriptionOfPatches = StrConcat(BriefDescriptionsOfPatches, Chars.LF);
		
	PartsOfMessage = New Array;
	PartsOfMessage.Add(StandardSubsystemsServer.MessageTextOnDynamicUpdate(CheckParameters)); 
	If ValueIsFilled(NewPatchesDetails) Then
		PartsOfMessage.Add("");
		PartsOfMessage.Add(BriefDescriptionOfPatches);
		If ShouldOutputDetails Then
			PartsOfMessage.Add("...");
			PartsOfMessage.Add("");
			PartsOfMessage.Add(NStr("vi = '<a href = ""%1"">Chi tiết hơn</a>';
									|ru = '<a href = ""%1"">Подробнее</a>';
									|en = '<a href = ""%1"">View details</a>'; fa = '<a href = ""%1"">View details</a>';
									|it = '<a href = ""%1"">Подробнее</a>';
									|pl = '<a href = ""%1"">View details</a>';
									|tr = '<a href = ""%1"">Daha fazla</a>'"));
		EndIf; 
	EndIf;
	Message = StrConcat(PartsOfMessage, Chars.LF);
	
	Items.Text.Title = StringFunctions.FormattedString(Message, "LinkAction");
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityAvailability(Form)
	
	If Form.PossibleAction = 0 Then
		RunActionButtonTitle = NStr("vi = 'Khởi động lại';
									|ru = 'Перезапустить';
									|en = 'Restart'; fa = 'راه‌اندازی مجدد';
									|it = 'Перезапустить';
									|pl = 'Restart';
									|tr = 'Yeniden başlat'");
		Form.Items.RestartTime.Enabled = False;
	ElsIf Form.PossibleAction = 1 Then
		RunActionButtonTitle = NStr("vi = 'Dự định';
									|ru = 'Запланировать';
									|en = 'Schedule'; fa = 'برنامه زمان‌بندی';
									|it = 'Запланировать';
									|pl = 'Schedule';
									|tr = 'Planla'");
		Form.Items.RestartTime.Enabled = True;
	ElsIf Form.PossibleAction = 2 Then
		RunActionButtonTitle = NStr("vi = 'Nhắc vào ngày mai';
									|ru = 'Напомнить завтра';
									|en = 'Remind me tomorrow'; fa = 'فردا یادآوری شود';
									|it = 'Ricordamelo domani';
									|pl = 'Przypomnij jutro';
									|tr = 'Yarın hatırlat'");
		Form.Items.RestartTime.Enabled = False;
	EndIf;
	
	Form.Items.FormExecuteAction.Title = RunActionButtonTitle;
	
EndProcedure

&AtClient
Procedure DoScheduleRestart()
	StandardSubsystemsClient.DisableScheduledRestart();
	SessionDate = CommonClient.SessionDate();
	SessionTime =  Date('00010101') + (SessionDate-BegOfDay(SessionDate));
	SecondsBeforeRestart = RestartTime - SessionTime;
	If SecondsBeforeRestart < 560 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Thời gian khởi động tối thiểu: %1';
				|ru = 'Минимальное время перезапуска: %1';
				|en = 'Choose a time after %1'; fa = 'Choose a time after %1';
				|it = 'Минимальное время перезапуска: %1';
				|pl = 'Choose a time after %1';
				|tr = 'Minimum yeniden başlatma süresi: %1'"), Format(SessionTime + 600, "DF=HH:mm"));
		CommonClient.MessageToUser(MessageText,,"RestartTime");
		Return;
	EndIf;
	StandardSubsystemsClient.AttachHandlersOfRestartAndNotificationsWait(SecondsBeforeRestart);
	SaveSettingAppRestartTimeForApplyPatches(RestartTime);
	RemindTomorrowOnServer();
	Close();
EndProcedure 

&AtServerNoContext
Procedure SaveSettingAppRestartTimeForApplyPatches(RestartTime)
	Common.CommonSettingsStorageSave("UserCommonSettings",
		"AppRestartTimeForApplyPatches",
		RestartTime);
EndProcedure



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
