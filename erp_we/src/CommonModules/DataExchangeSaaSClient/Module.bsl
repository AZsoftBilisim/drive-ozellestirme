///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Client application session startup handler.
// If the current session is a standalone workstation session, the procedure notifies a user
// that data synchronization with a web application is required
// (provided that the appropriate flag is set).
//
Procedure OnStart(Parameters) Export
	
	ClientRunParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If ClientRunParameters.DataSeparationEnabled Then
		Return;
	EndIf;
	
	If ClientRunParameters.IsStandaloneWorkplace Then
		ParameterName = "StandardSubsystems.SuggestDataSynchronizationWithWebApplicationOnExit";
		If ApplicationParameters[ParameterName] = Undefined Then
			ApplicationParameters.Insert(ParameterName, Undefined);
		EndIf;
		
		ApplicationParameters["StandardSubsystems.SuggestDataSynchronizationWithWebApplicationOnExit"] =
			ClientRunParameters.SynchronizeDataWithWebApplicationOnExit;
		
		If ClientRunParameters.SynchronizeDataWithWebApplicationOnStart Then
			
			ShowUserNotification(NStr("vi = 'Làm việc độc lập';
										|ru = 'Автономная работа';
										|en = 'Standalone mode'; fa = 'حالت مستقل';
										|it = 'Lavoro autonomo';
										|pl = 'Praca offline';
										|tr = 'Tek başına mod'"), "e1cib/app/DataProcessor.DataExchangeExecution",
				NStr("vi = 'Nên đồng bộ dữ liệu với ứng dụng trên Internet.';
					|ru = 'Рекомендуется синхронизировать данные с приложением в Интернете.';
					|en = 'It is recommended that you synchronize the workstation data with the web application.'; fa = 'It is recommended that you synchronize the workstation data with the web application.';
					|it = 'Si consiglia di sincronizzare i dati con l''applicazione su Internet.';
					|pl = 'Zalecana jest synchronizacja danych z aplikacją w Internecie.';
					|tr = 'Verileri Internet uygulaması ile senkronize etmeniz önerilir.'"), PictureLib.Information32);
			
		EndIf;
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Handlers of service events of BSP subsystems

// Redefines a list of warnings displayed to a user before they exit the application.
//
// Parameters:
//  Cancel - Boolean - indicates whether the application closing must be canceled. If the parameter
//                   is set to True in the handler, the application is not closed.
//  Warnings - Array - you can add elements of the Structure type to the array,
//                            the structure properties are listed in StandardSubsystemsClient.BeforeExit.
//
Procedure BeforeExit(Cancel, Warnings) Export
	
	StandaloneModeParameters = StandardSubsystemsClient.ClientParameter("StandaloneModeParameters");
	
	If ApplicationParameters["StandardSubsystems.SuggestDataSynchronizationWithWebApplicationOnExit"] = True
		And StandaloneModeParameters.SynchronizationWithServiceNotExecutedLongTime Then
		
		WarningParameters = StandardSubsystemsClient.WarningOnExit();
		WarningParameters.ExtendedTooltip = NStr("vi = 'Trong nhiều trường hợp, việc đồng bộ hóa dữ liệu có thể mất nhiều thời gian:
	        | - kênh kết nối chậm;
	        | - khối lượng dữ liệu lớn;
	        | - đang cập nhật ứng dụng trên Internet.';
	        |ru = 'В некоторых случаях синхронизация данных может занять длительное время:
	        | - медленный канал связи;
	        | - большой объем данных;
	        | - доступно обновление приложения в Интернете.';
	        |en = 'Data synchronization may take a while if:
	        | • The connection is slow
	        | • The amount of data to sync is big
	        | • An application update is available online'; fa = 'همگام‌سازی داده ممکن است زمان‌بر باشد اگر:
	        | • اتصال کند باشد
	        | • حجم داده قابل همگام‌سازی زیاد باشد
	        | • به‌روزرسانی برنامه به‌صورت آنلاین در دسترس باشد';
	        |it = 'In alcuni casi, la sincronizzazione dei dati può richiedere molto tempo: 
	        |- canale di comunicazione lento;
	        |- grande quantità di dati;
	        |- è disponibile un aggiornamento dell''applicazione su Internet.';
	        |pl = 'W niektórych przypadkach synchronizacja danych może zająć dużo czasu:
	        | - wolny kanał komunikacji;
	        | - duża ilość danych;
	        | - możesz zaktualizować aplikację w Internecie.';
	        |tr = 'Bazı durumlarda veri senkronizasyonu uzun sürebilir: 
	        |- yavaş iletişim kanalı; 
	        |- büyük veri hacmi; 
	        |- İnternet üzerinden uygulama güncellemesi mevcut.'");

		WarningParameters.WarningText = NStr("vi = 'Chưa thực hiện đồng bộ dữ liệu với ứng dụng trên Internet.';
											|ru = 'Не выполнена синхронизация данных с приложением в Интернете.';
											|en = 'Data is not synchronized with the web application.'; fa = 'Data is not synchronized with the web application.';
											|it = 'Non è stata configurata la sincronizzazione dati con l''applicazione su Internet.';
											|pl = 'Nie jest wykonana synchronizacja danych z aplikacją w Internecie.';
											|tr = 'Internet uygulaması ile veri senkronizasyonu yapılmadı.'");
		WarningParameters.CheckBoxText = NStr("vi = 'Đồng bộ dữ liệu với dứng dụng trên Internet';
												|ru = 'Синхронизировать данные с приложением в Интернете';
												|en = 'Synchronize data with web application'; fa = 'Synchronize data with web application';
												|it = 'Sincronizzare i dati con l''applicazione su Internet';
												|pl = 'Synchronizuj dane z aplikacją w Internecie';
												|tr = 'Verileri Internet uygulaması ile senkronize et'");
		WarningParameters.Priority = 80;
		
		ActionIfFlagSet = WarningParameters.ActionIfFlagSet;
		ActionIfFlagSet.Form = "DataProcessor.DataExchangeExecution.Form.Form";
		
		FormParameters = StandaloneModeParameters.DataExchangeExecutionFormParameters;
		FormParameters = CommonClient.CopyRecursive(FormParameters, False);
		FormParameters.Insert("ShouldExitApp", True);
		ActionIfFlagSet.FormParameters = FormParameters;
		
		Warnings.Add(WarningParameters);
	EndIf;
	
EndProcedure

#EndRegion
