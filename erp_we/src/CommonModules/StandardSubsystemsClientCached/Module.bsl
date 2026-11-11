///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// See StandardSubsystemsClient.ClientParametersOnStart().
Function ClientParametersOnStart() Export
	
	CommonStartTime = CurrentUniversalDateInMilliseconds();
	Indicators = ?(StandardSubsystemsClientServer.ShouldRegisterPerformanceIndicators(),
		New Array, Undefined);
	
	CheckIfAppStartupFinished(True);
	
	ApplicationStartParameters = ApplicationParameters["StandardSubsystems.ApplicationStartParameters"];
	
	Parameters = New Structure;
	Parameters.Insert("RetrievedClientParameters", Undefined);
	
	If ApplicationStartParameters.Property("RetrievedClientParameters")
		And TypeOf(ApplicationStartParameters.RetrievedClientParameters) = Type("Structure") Then
		
		Parameters.Insert("RetrievedClientParameters", CommonClient.CopyRecursive(
			ApplicationStartParameters.RetrievedClientParameters));
	EndIf;
	
	If ApplicationStartParameters.Property("SkipClearingDesktopHiding") Then
		Parameters.Insert("SkipClearingDesktopHiding");
	EndIf;
	
	If ApplicationStartParameters.Property("InterfaceOptions")
	   And TypeOf(Parameters.RetrievedClientParameters) = Type("Structure") Then
		
		Parameters.RetrievedClientParameters.Insert("InterfaceOptions");
	EndIf;
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	StandardSubsystemsClient.FillInTheClientParametersOnTheServer(Parameters);
	AddMainIndicator(True, Indicators, StartMoment,
		"StandardSubsystemsClient.FillInTheClientParametersOnTheServer");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	ClientParameters = StandardSubsystemsServerCall.ClientParametersOnStart(Parameters);
	AddMainIndicator(True, Indicators, StartMoment,
		"StandardSubsystemsServerCall.ClientParametersOnStart");
	
	If Indicators <> Undefined And ValueIsFilled(ClientParameters.PerformanceIndicators_) Then
		CommonClientServer.SupplementArray(Indicators,
			ClientParameters.PerformanceIndicators_);
	EndIf;
	
	If ApplicationStartParameters.Property("RetrievedClientParameters")
		And ApplicationStartParameters.RetrievedClientParameters <> Undefined
		And Not ApplicationStartParameters.Property("InterfaceOptions") Then
		
		ApplicationStartParameters.Insert("InterfaceOptions", ClientParameters.InterfaceOptions);
	EndIf;
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	StandardSubsystemsClient.FillClientParameters(ClientParameters);
	AddMainIndicator(True, Indicators, StartMoment,
		"StandardSubsystemsClient.FillClientParameters");
	
	// Updating the desktop hiding status on client by the state on server.
	StartMoment = CurrentUniversalDateInMilliseconds();
	StandardSubsystemsClient.HideDesktopOnStart(
		Parameters.HideDesktopOnStart, True);
	AddMainIndicator(True, Indicators, StartMoment,
		"StandardSubsystemsClient.HideDesktopOnStart");
	
	AddMainIndicator(True, Indicators, CommonStartTime,
		"StandardSubsystemsClientCached.ClientParametersOnStart", True);
	
	Return ClientParameters;
	
EndFunction

// See StandardSubsystemsClient.ClientRunParameters().
Function ClientRunParameters() Export
	
	CommonStartTime = CurrentUniversalDateInMilliseconds();
	Indicators = ?(StandardSubsystemsClientServer.ShouldRegisterPerformanceIndicators(),
		New Array, Undefined);
	
	CheckIfAppStartupFinished();
	
	ClientProperties = New Structure;
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	StandardSubsystemsClient.FillInTheClientParametersOnTheServer(ClientProperties);
	AddMainIndicator(False, Indicators, StartMoment,
		"StandardSubsystemsClient.FillInTheClientParametersOnTheServer");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	ClientParameters = StandardSubsystemsServerCall.ClientRunParameters(ClientProperties);
	AddMainIndicator(False, Indicators, StartMoment,
		"StandardSubsystemsServerCall.ClientRunParameters");
	
	If Indicators <> Undefined And ValueIsFilled(ClientParameters.PerformanceIndicators_) Then
		CommonClientServer.SupplementArray(Indicators,
			ClientParameters.PerformanceIndicators_);
	EndIf;
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	StandardSubsystemsClient.FillClientParameters(ClientParameters);
	AddMainIndicator(False, Indicators, StartMoment,
		"StandardSubsystemsClient.FillClientParameters");
	
	AddMainIndicator(False, Indicators, CommonStartTime,
		"StandardSubsystemsClientCached.ClientRunParameters", True);
	
	Return ClientParameters;
	
EndFunction

// See StandardSubsystemsCached.RefsByPredefinedItemsNames
Function RefsByPredefinedItemsNames(FullMetadataObjectName) Export
	
	Return StandardSubsystemsServerCall.RefsByPredefinedItemsNames(FullMetadataObjectName);
	
EndFunction

Procedure CheckIfAppStartupFinished(OnlyBeforeSystemStartup = False)
	
	ParameterName = "StandardSubsystems.ApplicationStartCompleted";
	If ApplicationParameters[ParameterName] = Undefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã xảy ra tình huống bất thường, khi khởi động ứng dụng.
			           |
			           |Thông tin kỹ thuật về vấn đề:
			           |Lần gọi không hợp lệ%1khi khởi động ứng dụng.
			           |Thủ tục đầu tiên được gọi ra từ hàm sự kiện %2 phải là thủ tục %3.';
			           |ru = 'Возникла непредвиденная ситуация при запуске приложения.
			           |
			           |Техническая информация о проблеме:
			           |Недопустимый вызов %1 при запуске приложения.
			           |Первой процедурой, которая вызывается из обработчика события %2, должна быть процедура %3.';
			           |en = 'Exception occurred during startup.
			           |
			           |Technical details:
			           |Invalid call %1 during startup.
			           |The first procedure that is called from the %2 event handler must be %3.'; fa = 'Exception occurred during startup.
			           |
			           |Technical details:
			           |Invalid call %1 during startup.
			           |The first procedure that is called from the %2 event handler must be %3.';
			           |it = 'Возникла непредвиденная ситуация при запуске приложения.
			           |
			           |Техническая информация о проблеме:
			           |Недопустимый вызов %1 при запуске приложения.
			           |Первой процедурой, которая вызывается из обработчика события %2, должна быть процедура %3.';
			           |pl = 'Exception occurred during startup.
			           |
			           |Technical details:
			           |Invalid call %1 during startup.
			           |The first procedure that is called from the %2 event handler must be %3.';
			           |tr = 'Uygulama başlatılırken beklenmedik bir durum oluştu.
			           |
			           |Sorun hakkında teknik bilgi:
			           |Uygulama başlatılırken izin verilmeyen çağrılar %1.
			           | %2 etkinlik işleyicisinden çağrılan ilk prosedürün %3 prosedürü olması zorunludur.'"),
			"StandardSubsystemsClient.ClientRunParameters",
			"BeforeStart", 
			"StandardSubsystemsClient.BeforeStart");
		Raise ErrorText;
	EndIf;
	
	If OnlyBeforeSystemStartup Then
		Return;
	EndIf;
	
	If Not StandardSubsystemsClient.ApplicationStartCompleted() Then
		If StandardSubsystemsClient.ApplicationStartupLogicDisabled() Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Thao tác không khả dụng khi khởi động với tham số %1.';
					|ru = 'Действие недоступно при запуске с параметром %1.';
					|en = 'The action is unavailable when running with the %1 parameter.'; fa = 'The action is unavailable when running with the %1 parameter.';
					|it = 'L''azione non disponibile all''avvio con il parametro %1.';
					|pl = 'Czynność jest niedostępna przy uruchomieniu z parametrem %1.';
					|tr = '%1 parametresi ile başlatıldığında işlem kullanılamaz.'"),
				"DisableSystemStartupLogic");
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã xảy ra tình huống bất thường khi khởi động ứng dụng.
			           |
			           |Thông tin kỹ thuật về vấn đề:
			           |Lần gọi không hợp lệ %1 khi khởi động ứng dụng. Cần gọi ra %2 cho đến khi thủ tục %3 hoàn thành.
			           |Thủ tục được gọi ra (theo trình tự ngược lại):
			           |%4';
			           |ru = 'Возникла непредвиденная ситуация при запуске приложения.
			           |
			           |Техническая информация о проблеме:
			           |Недопустимый вызов %1 при запуске приложения. Следует вызывать %2, пока процедура %3 еще не завершена.
			           |Вызванные процедуры (в обратном порядке):
			           |%4';
			           |en = 'An exception occurred during startup.
			           |
			           |Details:
			           |Invalid %1 call during startup. Call %2 while the procedure %3 is still running.
			           |The invoked procedures (most recent first):
			           |%4'; fa = 'An exception occurred during startup.
			           |
			           |Details:
			           |Invalid %1 call during startup. Call %2 while the procedure %3 is still running.
			           |The invoked procedures (most recent first):
			           |%4';
			           |it = 'Возникла непредвиденная ситуация при запуске приложения.
			           |
			           |Техническая информация о проблеме:
			           |Недопустимый вызов %1 при запуске приложения. Следует вызывать %2, пока процедура %3 еще не завершена.
			           |Вызванные процедуры (в обратном порядке):
			           |%4';
			           |pl = 'An exception occurred during startup.
			           |
			           |Details:
			           |Invalid %1 call during startup. Call %2 while the procedure %3 is still running.
			           |The invoked procedures (most recent first):
			           |%4';
			           |tr = 'Возникла непредвиденная ситуация при запуске приложения.
			           |
			           |Техническая информация о проблеме:
			           |Недопустимый вызов %1 при запуске приложения. Следует вызывать %2, пока процедура %3 еще не завершена.
			           |Вызванные процедуры (в обратном порядке):
			           |%4'"),
				"StandardSubsystemsClient.ClientRunParameters", 
				"StandardSubsystemsClient.ClientParametersOnStart",
				"StandardSubsystemsClient.BeforeStart",
				StandardSubsystemsClient.CalledProceduresBeforeStart());
		EndIf;
		Raise ErrorText;
	EndIf;

EndProcedure

Procedure AddMainIndicator(OnStart, Indicators, StartMoment, ProcedureName, Shared = False)
	
	If Indicators = Undefined Then
		Return;
	EndIf;
	
	Duration = CurrentUniversalDateInMilliseconds() - StartMoment;
	If Not Shared And Not ValueIsFilled(Duration) Then
		Return;
	EndIf;
	
	Text = Format(Duration / 1000, "ND=6; NFD=3; NZ=000,000; NLZ=") + " " + ProcedureName;
	
	If Shared Then
		Indicators.Insert(0, Text);
		WriteIndicators(OnStart, Indicators, Duration);
		Return;
	Else
		Indicators.Add("  " + Text);
	EndIf;
	
EndProcedure

Procedure WriteIndicators(OnStart, Indicators, TotalDuration)
	
	Comment = StrConcat(Indicators, Chars.LF);
	
	CallsStack = "";
	Try
		Raise NStr("vi = 'Ngăn xếp lần gọi:';
					|ru = 'Стек вызова:';
					|en = 'Call stack:'; fa = 'Call stack:';
					|it = 'Call stack:';
					|pl = 'Call stack:';
					|tr = 'Çağrı yığını:'");
	Except
		CallsStack = ErrorProcessing.DetailErrorDescription(ErrorInfo());
	EndTry;
	
	StandardSubsystemsServerCall.WritePerformanceIndicators(OnStart, Comment, CallsStack);
	
EndProcedure

// See ServerNotificationsInternalClientServer.AreClientNotificationsAvailable
Function AreClientNotificationsAvailable() Export
	Return ServerNotificationsInternalClientServer.AreClientNotificationsAvailable();
EndFunction

#Region ForMetadataObjectIDsCatalog

// See Catalogs.MetadataObjectIDs.IDPresentation
Function MetadataObjectIDPresentation(Ref) Export
	
	Return StandardSubsystemsServerCall.MetadataObjectIDPresentation(Ref);
	
EndFunction

#EndRegion

#EndRegion