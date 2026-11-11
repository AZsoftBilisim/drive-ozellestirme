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
	
	EventLogEventName = ExternalResourcesOperationsLock.EventLogEventName();
	
	LockParameters = ExternalResourcesOperationsLock.SavedLockParameters();
	CheckServerName = LockParameters.CheckServerName;
	
	If Parameters.LockDecisionMaking Then
		
		UnlockText = ScheduledJobsInternal.SettingValue("UnlockCommandPlacement");
		DataSeparationEnabled = Common.DataSeparationEnabled();
		DataSeparationChanged = LockParameters.DataSeparationEnabled <> DataSeparationEnabled;
		
		If DataSeparationEnabled Then
			Items.InfobaseMoved.Title = NStr("vi = 'Đã di chuyển ứng dụng';
											|ru = 'Приложение перемещено';
											|en = 'Moved application'; fa = 'Moved application';
											|it = 'Applicazione spostata';
											|pl = 'Aplikacja została przemieszczona';
											|tr = 'Uygulama taşındı'");
			Items.IsInfobaseCopy.Title = NStr("vi = 'Đây là bản sao ứng dụng';
												|ru = 'Это копия приложения';
												|en = 'Application copy'; fa = 'Application copy';
												|it = 'Questa è una copia dell''applicazione';
												|pl = 'To jest kopia aplikacji';
												|tr = 'Bu uygulamanın kopyası'");
			Title = NStr("vi = 'Đã di chuyển hoặc khôi phục ứng dụng từ bản sao dự phòng';
						|ru = 'Приложение было перемещено или восстановлено из резервной копии';
						|en = 'Moved or restored application'; fa = 'Moved or restored application';
						|it = 'L''applicazione è stata spostata o ripristinata dal backup';
						|pl = 'Aplikacja została przemieszczona albo odzyskana z kopii zapasowej';
						|tr = 'Uygulama taşındı veya yedek kopyadan yenilendi'");
		EndIf;
		
		If Not DataSeparationEnabled And Not DataSeparationChanged Then
			
			ScalableClusterClarification = ?(Common.FileInfobase(), "",
				NStr("vi = '• Khi làm việc trong một cụm có thể mở rộng, để tránh xác thực sai do thay đổi máy tính 
				           | hoạt động như máy chủ sản xuất, hãy tắt tính năng kiểm tra tên máy tính, nhấp vào <b>Hơn nữa - Kiểm tra tên máy chủ.</b>';
				           |ru = '• При работе в масштабируемом кластере для предотвращения ложных срабатываний из-за смены компьютеров, выступающих
				           |  в роли рабочих серверов, отключите проверку имени компьютера, нажмите <b>Еще - Проверять имя сервера.</b>';
				           |en = '• For scalable clusters, to prevent false starts due to change of computers acting as production servers
				           |, disable the computer name check by clicking <b>More > Check server name.</b>'; fa = '• For scalable clusters, to prevent false starts due to change of computers acting as production servers
				           |, disable the computer name check by clicking <b>More > Check server name.</b>';
				           |it = '• При работе в масштабируемом кластере для предотвращения ложных срабатываний из-за смены компьютеров, выступающих
				           |  в роли рабочих серверов, отключите проверку имени компьютера, нажмите <b>Еще - Проверять имя сервера.</b>';
				           |pl = '• For scalable clusters, to prevent false starts due to change of computers acting as production servers
				           |, disable the computer name check by clicking <b>More > Check server name.</b>';
				           |tr = '• Ölçeklenebilir bir kümede çalışırken, üretim sunucusu görevi gören
				           | bilgisayarların değiştirilmesinden kaynaklanan yanlış pozitifleri önlemek için bilgisayar adı denetimini devre dışı bırakın, <b> tuşuna basın Ayrıca - Sunucu adını kontrol edin.</b>'"));
			
			WarningLabel = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã chặn làm việc với tất cả nguồn ngoài (đồng bộ dữ liệu, gửi email...) đang thực hiện theo lịch biểu,
				           |để ngăn ngừa xung đột với cơ sở thông tin chính.
				           |
				           |%1
				           |
				           |<a href = ""%2"">Thông tin kỹ thuật về nguyên nhân chặn</a>
				           |
				           |• Nếu cơ sở thông tin được sử dụng để ghi nhận kế toán, hãy nhấp vào <b>Cơ sở thông tin đã di chuyển</b>.
				           |• Nếu đây là bản sao cơ sở thông tin, hãy nhấp vào <b>Đây là bản sao cơ sở thông tin</b>.
				           |%3
				           |
				           |%4';
				           |ru = 'Работа со всеми внешними ресурсами (синхронизация данных, отправка почты и т.п.), выполняемая по расписанию,
				           |заблокирована для предотвращения конфликтов с основной информационной базой.
				           |
				           |%1
				           |
				           |<a href = ""%2"">Техническая информация о причине блокировки</a>
				           |
				           |• Если информационная база будет использоваться для ведения учета, нажмите <b>Информационная база перемещена</b>.
				           |• Если это копия информационной базы, нажмите <b>Это копия информационной базы</b>.
				           |%3
				           |
				           |%4';
				           |en = 'Scheduled online activities such as data synchronization and emailing are disabled
				           |to prevent conflicts with the main infobase.
				           |
				           |%1
				           |
				           |<a href = ""%2"">Technical information</a>
				           |
				           | • If you are going to use the infobase for accounting, select <b>Moved infobase</b>.
				           | • If this is an infobase copy, select <b>Infobase copy</b>.
				           |%3
				           |
				           |%4'; fa = 'Scheduled online activities such as data synchronization and emailing are disabled
				           |to prevent conflicts with the main infobase.
				           |
				           |%1
				           |
				           |<a href = ""%2"">Technical information</a>
				           |
				           | • If you are going to use the infobase for accounting, select <b>Moved infobase</b>.
				           | • If this is an infobase copy, select <b>Infobase copy</b>.
				           |%3
				           |
				           |%4';
				           |it = 'Работа со всеми внешними ресурсами (синхронизация данных, отправка почты и т.п.), выполняемая по расписанию,
				           |заблокирована для предотвращения конфликтов с основной информационной базой.
				           |
				           |%1
				           |
				           |<a href = ""%2"">Техническая информация о причине блокировки</a>
				           |
				           |• Если информационная база будет использоваться для ведения учета, нажмите <b>Информационная база перемещена</b>.
				           |• Если это копия информационной базы, нажмите <b>Это копия информационной базы</b>.
				           |%3
				           |
				           |%4';
				           |pl = 'Scheduled online activities such as data synchronization and emailing are disabled
				           |to prevent conflicts with the main infobase.
				           |
				           |%1
				           |
				           |<a href = ""%2"">Technical information</a>
				           |
				           | • If you are going to use the infobase for accounting, select <b>Moved infobase</b>.
				           | • If this is an infobase copy, select <b>Infobase copy</b>.
				           |%3
				           |
				           |%4';
				           |tr = 'Ana infobase ile çakışmaları önlemek için tüm harici kaynaklarla (veri senkronizasyonu, posta gönderme vb.) planlı çalışma 
				           |engellenir.
				           |
				           |%1
				           |
				           |<a href = ""%2"">Engelleme nedeni hakkında teknik bilgiler</a>
				           |
				           |• Infobase muhasebe için kullanılacaksa, <b>tıklayın Infobase taşındı</b>.
				           |• Bu infobase''nin bir kopyasıysa, <b> tıklayın Bu </b> infobase''nin kopyasıdır.
				           |%3
				           |
				           |%4'"),
				LockParameters.LockReason,
				"EventLog",
				ScalableClusterClarification,
				UnlockText);
		ElsIf Not DataSeparationEnabled And DataSeparationChanged Then
			WarningLabel = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Công việc đã lên lịch với tất cả các tài nguyên bên ngoài (đồng bộ hóa dữ liệu, gửi thư, v.v.) bị 
				           | chặn để tránh xung đột với ứng dụng trên Internet.
				           |
				           |<b>Infobase đã được tải xuống từ một ứng dụng internet</b>
				           |
				           |• Nếu infobase sẽ được sử dụng cho mục đích kế toán, hãy nhấp vào <b>Infobase đã di chuyển</b>.
				           |• Nếu đây là bản sao của infobase, hãy nhấp vào <b>Đây là bản sao của infobase</b>.
				           |
				           |%1';
				           |ru = 'Работа со всеми внешними ресурсами (синхронизация данных, отправка почты и т.п.), выполняемая по расписанию,
				           |заблокирована для предотвращения конфликтов с приложением в Интернете.
				           |
				           |<b>Информационная база была загружена из приложения в Интернете</b>
				           |
				           |• Если информационная база будет использоваться для ведения учета, нажмите <b>Информационная база перемещена</b>.
				           |• Если это копия информационной базы, нажмите <b>Это копия информационной базы</b>.
				           |
				           |%1';
				           |en = 'Scheduled online activities such as data synchronization and emailing are disabled
				           |to prevent conflicts with the web application.
				           |
				           |<b>This infobase was imported from the web application</b>.
				           |
				           | • If you are going to use the infobase for accounting, select <b>Moved infobase</b>.
				           | • If this is an infobase copy, select <b>Infobase copy</b>.
				           |
				           |%1'; fa = 'Scheduled online activities such as data synchronization and emailing are disabled
				           |to prevent conflicts with the web application.
				           |
				           |<b>This infobase was imported from the web application</b>.
				           |
				           | • If you are going to use the infobase for accounting, select <b>Moved infobase</b>.
				           | • If this is an infobase copy, select <b>Infobase copy</b>.
				           |
				           |%1';
				           |it = 'Работа со всеми внешними ресурсами (синхронизация данных, отправка почты и т.п.), выполняемая по расписанию,
				           |заблокирована для предотвращения конфликтов с приложением в Интернете.
				           |
				           |<b>Информационная база была загружена из приложения в Интернете</b>
				           |
				           |• Если информационная база будет использоваться для ведения учета, нажмите <b>Информационная база перемещена</b>.
				           |• Если это копия информационной базы, нажмите <b>Это копия информационной базы</b>.
				           |
				           |%1';
				           |pl = 'Scheduled online activities such as data synchronization and emailing are disabled
				           |to prevent conflicts with the web application.
				           |
				           |<b>This infobase was imported from the web application</b>.
				           |
				           | • If you are going to use the infobase for accounting, select <b>Moved infobase</b>.
				           | • If this is an infobase copy, select <b>Infobase copy</b>.
				           |
				           |%1';
				           |tr = 'İnternet uygulaması ile çakışmaları önlemek için tüm harici kaynaklarla (veri senkronizasyonu, posta gönderme vb.) planlı çalışma 
				           |engellenir.
				           |
				           |<b>Infobase İnternet uygulamasından yüklendi</b>
				           |
				           |• Infobase muhasebe için kullanılacaksa<b>tıklayın Infobase taşındı</b>.
				           |• Bu infobase''nin bir kopyasıysa, <b> tıklayın Bu </b> infobase''nin kopyasıdır.
				           |
				           |%1'"),
				UnlockText);
		ElsIf DataSeparationEnabled And Not DataSeparationChanged Then
			WarningLabel = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Công việc đã lên lịch với tất cả các tài nguyên bên ngoài (đồng bộ hóa dữ liệu, gửi thư, v.v.) bị
				           | chặn để tránh xung đột với ứng dụng trên Internet.
				           |
				           |<b>Ứng dụng đã được di chuyển</b>
				           |
				           |• Nếu ứng dụng sẽ được sử dụng cho mục đích kế toán, hãy nhấp vào <b>Ứng dụng đã được di chuyển</b>.
				           |•Nếu đó là một bản sao của ứng dụng, hãy nhấp vào <b>Đây là một bản sao của ứng dụng</b>.
				           |
				           |%1';
				           |ru = 'Работа со всеми внешними ресурсами (синхронизация данных, отправка почты и т.п.), выполняемая по расписанию,
				           |заблокирована для предотвращения конфликтов с приложением в Интернете.
				           |
				           |<b>Приложение было перемещено</b>
				           |
				           |• Если приложение будет использоваться для ведения учета, нажмите <b>Приложение перемещено</b>.
				           |• Если это копия приложения, нажмите <b>Это копия приложения</b>.
				           |
				           |%1';
				           |en = 'Scheduled online activities such as data synchronization and emailing are disabled
				           |to prevent conflicts with the web application.
				           |
				           |<b>The application was moved.</b>
				           |
				           | • If you are going to use the application for accounting, select <b>Moved application</b>.
				           | • If this is an application copy, select <b>Application copy</b>.
				           |
				           |%1'; fa = 'Scheduled online activities such as data synchronization and emailing are disabled
				           |to prevent conflicts with the web application.
				           |
				           |<b>The application was moved.</b>
				           |
				           | • If you are going to use the application for accounting, select <b>Moved application</b>.
				           | • If this is an application copy, select <b>Application copy</b>.
				           |
				           |%1';
				           |it = 'Работа со всеми внешними ресурсами (синхронизация данных, отправка почты и т.п.), выполняемая по расписанию,
				           |заблокирована для предотвращения конфликтов с приложением в Интернете.
				           |
				           |<b>Приложение было перемещено</b>
				           |
				           |• Если приложение будет использоваться для ведения учета, нажмите <b>Приложение перемещено</b>.
				           |• Если это копия приложения, нажмите <b>Это копия приложения</b>.
				           |
				           |%1';
				           |pl = 'Scheduled online activities such as data synchronization and emailing are disabled
				           |to prevent conflicts with the web application.
				           |
				           |<b>The application was moved.</b>
				           |
				           | • If you are going to use the application for accounting, select <b>Moved application</b>.
				           | • If this is an application copy, select <b>Application copy</b>.
				           |
				           |%1';
				           |tr = 'İnternet uygulaması ile çakışmaları önlemek için tüm harici kaynaklarla (veri senkronizasyonu, posta gönderme vb.) planlı çalışma 
				           |engellenir.
				           |
				           |<b>Uygulama taşındı</b>
				           |
				           |• Uygulama muhasebe için kullanılacaksa<b>tıklayın Uygulama taşındı</b>.
				           |• Bu uygulamanın bir kopyasıysa, <b> tıklayın Bu </b> uygulamasının kopyasıdır.
				           |
				           |%1'"),
				UnlockText);
		Else // If DataSeparationEnabled and DataSeparationChanged
			WarningLabel = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Công việc đã lên lịch với tất cả các tài nguyên bên ngoài (đồng bộ hóa dữ liệu, gửi thư, v.v.) bị
				           | chặn để tránh xung đột với phiên bản cục bộ.
				           |
				           |Ứng dụng đã được tải xuống từ phiên bản cục bộ
				           |
				           |• Nếu ứng dụng sẽ được sử dụng cho mục đích kế toán, hãy nhấp vào <b>Ứng dụng đã được di chuyển</b>.
				           |• Nếu đó là một bản sao của ứng dụng, hãy nhấp vào <b>Đây là một bản sao của ứng dụng</b>.
				           |
				           |%1';
				           |ru = 'Работа со всеми внешними ресурсами (синхронизация данных, отправка почты и т.п.), выполняемая по расписанию,
				           |заблокирована для предотвращения конфликтов с локальной версией.
				           |
				           |Приложение было загружено из локальной версии
				           |
				           |• Если приложение будет использоваться для ведения учета, нажмите <b>Приложение перемещено</b>.
				           |• Если это копия приложения, нажмите <b>Это копия приложения</b>.
				           |
				           |%1';
				           |en = 'Scheduled online activities such as data synchronization and emailing are disabled
				           |to prevent conflicts with the local version.
				           |
				           |The application was imported from the local version.
				           |
				           | • If you are going to use the application for accounting, select <b>Moved application</b>.
				           | • If this is an application copy, select <b>Application copy</b>.
				           |
				           |%1'; fa = 'Scheduled online activities such as data synchronization and emailing are disabled
				           |to prevent conflicts with the local version.
				           |
				           |The application was imported from the local version.
				           |
				           | • If you are going to use the application for accounting, select <b>Moved application</b>.
				           | • If this is an application copy, select <b>Application copy</b>.
				           |
				           |%1';
				           |it = 'Работа со всеми внешними ресурсами (синхронизация данных, отправка почты и т.п.), выполняемая по расписанию,
				           |заблокирована для предотвращения конфликтов с локальной версией.
				           |
				           |Приложение было загружено из локальной версии
				           |
				           |• Если приложение будет использоваться для ведения учета, нажмите <b>Приложение перемещено</b>.
				           |• Если это копия приложения, нажмите <b>Это копия приложения</b>.
				           |
				           |%1';
				           |pl = 'Scheduled online activities such as data synchronization and emailing are disabled
				           |to prevent conflicts with the local version.
				           |
				           |The application was imported from the local version.
				           |
				           | • If you are going to use the application for accounting, select <b>Moved application</b>.
				           | • If this is an application copy, select <b>Application copy</b>.
				           |
				           |%1';
				           |tr = 'Yerel sürüm ile çakışmaları önlemek için tüm harici kaynaklarla (veri senkronizasyonu, posta gönderme vb.) planlı çalışma 
				           |engellenir.
				           |
				           |Uygulama yerel sürümden indirildi
				           |
				           |• Uygulama muhasebe için kullanılacaksa<b>tıklayın Uygulama taşındı</b>.
				           |• Bu uygulamanın bir kopyasıysa, <b> tıklayın Bu </b> uygulamasının kopyasıdır.
				           |
				           |%1'"),
				UnlockText);
		EndIf;
		
		Items.WarningLabel.Title = StringFunctions.FormattedString(WarningLabel);
		
		If Common.FileInfobase() Then
			Items.FormMoreGroup.Visible = False;
		Else
			Items.FormCheckServerName.Check = CheckServerName;
			Items.FormHelp.Visible = False;
		EndIf;
		
	Else
		Items.FormParametersGroup.CurrentPage = Items.LockParametersGroup;
		Items.WarningLabel.Visible = False;
		Items.WriteAndClose.DefaultButton = True;
		Title = NStr("vi = 'Tham số phong tỏa làm việc với nguồn ngoài';
					|ru = 'Параметры блокировки работы с внешними ресурсами';
					|en = 'Lock settings of external resources'; fa = 'Lock settings of external resources';
					|it = 'Parametri di blocco del lavoro con risorse esterne';
					|pl = 'Parametry blokowania pracy z zasobami zewnętrznymi';
					|tr = 'Dış kaynak kilitleme seçenekleri'");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarningLabelURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("EventLogEvent", EventLogEventName);
	OpenForm("DataProcessor.EventLog.Form.EventLog", FormParameters);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure InfobaseMoved(Command)
	
	AllowExternalResources();
	StandardSubsystemsClient.SetAdvancedApplicationCaption();
	RefreshInterface();
	Close();
	
EndProcedure

&AtClient
Procedure IsInfobaseCopy(Command)
	
	DenyExternalResources();
	StandardSubsystemsClient.SetAdvancedApplicationCaption();
	RefreshInterface();
	Close();
	
EndProcedure

&AtClient
Procedure CheckServerName(Command)
	
	CheckServerName = Not CheckServerName;
	Items.FormCheckServerName.Check = CheckServerName;
	SetServerNameCheckInLockParameters(CheckServerName);
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	SetServerNameCheckInLockParameters(CheckServerName);
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure AllowExternalResources()
	
	ExternalResourcesOperationsLock.AllowExternalResources();
	
EndProcedure

&AtServerNoContext
Procedure DenyExternalResources()
	
	ExternalResourcesOperationsLock.DenyExternalResources();
	
EndProcedure

&AtServerNoContext
Procedure SetServerNameCheckInLockParameters(CheckServerName)
	
	ExternalResourcesOperationsLock.SetServerNameCheckInLockParameters(CheckServerName);
	
EndProcedure

#EndRegion
