#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.ThisNode Then
		Items.StandaloneWorkplace.Visible = False;
	Else
		If Not ValueIsFilled(Object.DocumentsExportStartDate) Then
			Object.DocumentsExportStartDate = BegOfDay(CurrentSessionDate());
		EndIf;
		StartDateOfDocumentUploadCopy = Object.DocumentsExportStartDate;
		Items.DocumentsExportStartDate.ToolTip = StrTemplate(NStr("vi = 'Chỉ những chứng từ có ngày lớn hơn hoặc bằng %1 mới được kết xuất vào chế độ độc lập';
																	|ru = 'В автономный режим будут выгружаться только те документы, дата которых больше или равна %1';
																	|en = 'Only documents with a date greater than or equal to %1 will be exported to standalone mode'; fa = 'Only documents with a date greater than or equal to %1 will be exported to standalone mode';
																	|it = 'Only documents with a date greater than or equal to %1 will be exported to standalone mode';
																	|pl = 'Only documents with a date greater than or equal to %1 will be exported to standalone mode';
																	|tr = 'Tek başına moda yalnızca tarihi %1''e eşit veya daha büyük olan belgeler aktarılacaktır'"), Format(Object.DocumentsExportStartDate, NStr("vi = 'DLF = D';
																																																					|ru = 'ДЛФ=Д';
																																																					|en = 'DLF=D'; fa = 'DLF=D';
																																																					|it = 'DLF=D';
																																																					|pl = 'DLF=D';
																																																					|tr = 'DLF=D'")));
		Items.StandaloneWorkplace.ToolTip = NStr("vi = 'Ứng dụng có khả năng làm việc ở chế độ ngoại tuyến. Khi có kết nối đến máy chủ chính, ứng dụng sẽ sao chép dữ liệu cần thiết vào cơ sở dữ liệu cục bộ, và sau khi mất kết nối, sẽ chuyển sang chế độ ngoại tuyến và tiếp tục làm việc với dữ liệu.';
												|ru = 'Приложение имеет возможность работать в автономном режиме. При наличии подключения к основному серверу приложение будет копировать необходимые данные в локальную базу, а после потери соединения переключится в автономный режим и продолжит работу с данными.';
												|en = 'The application can work offline. If you are connected to the main server, the application will copy the necessary data to the local infobase, and after losing the connection, it will switch to standalone mode and continue working with the data.'; fa = 'برنامه می‌تواند به‌صورت آفلاین کار کند. اگر به سرور اصلی متصل باشید، برنامه داده‌های لازم را در پایگاه اطلاعات محلی کپی می‌کند و پس از قطع اتصال، به حالت مستقل رفته و کار با داده‌ها را ادامه می‌دهد.';
												|it = 'The application can work offline. If you are connected to the main server, the application will copy the necessary data to the local infobase, and after losing the connection, it will switch to standalone mode and continue working with the data.';
												|pl = 'The application can work offline. If you are connected to the main server, the application will copy the necessary data to the local infobase, and after losing the connection, it will switch to standalone mode and continue working with the data.';
												|tr = 'Uygulama tek başına modda çalışabilme özelliğine sahiptir. Ana sunucuya bağlantı olduğunda gerekli verileri yerel veritabanına kopyalar, bağlantı kesildiğinde ise tek başına moda geçer ve verilerle çalışmaya devam eder.'");
		Items.DocumentsExportStartDate.Enabled = Not Object.EnableDataExchange;
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure EnableDataExchangeOnChange(Item)
	
	If Object.EnableDataExchange = True Then
		ValueList = New ValueList;
		ValueList.Add("Enable", NStr("vi = 'Bật';
									|ru = 'Включить';
									|en = 'Enable'; fa = 'فعال';
									|it = 'Enable';
									|pl = 'Enable';
									|tr = 'Etkinleştir'"));
		ValueList.Add("DontInclude", NStr("vi = 'Không bật';
											|ru = 'Не включать';
											|en = 'Do not add'; fa = 'افزوده نشود';
											|it = 'Non includere';
											|pl = 'Nie włączaj';
											|tr = 'Etkinleştirme'"));
		
		Notification = New CallbackDescription("AfterClosingQuestionEnableDataExchange", ThisObject);
		ShowQueryBox(Notification, NStr("vi = 'Sau khi bật đồng bộ, khi khởi động ứng dụng, quá trình trao đổi dữ liệu sẽ bắt đầu và có thể mất nhiều thời gian. Bật đồng bộ?';
										|ru = 'После включения синхронизации при запуске приложения начнется обмен данными, который может занять длительное время. Включить синхронизацию?';
										|en = 'After enabling synchronization, data exchange will begin when the application is launched, which may take a long time. Enable synchronization?'; fa = 'After enabling synchronization, data exchange will begin when the application is launched, which may take a long time. Enable synchronization?';
										|it = 'After enabling synchronization, data exchange will begin when the application is launched, which may take a long time. Enable synchronization?';
										|pl = 'After enabling synchronization, data exchange will begin when the application is launched, which may take a long time. Enable synchronization?';
										|tr = 'Senkronizasyon etkinleştirildikten sonra uygulama başlatıldığında uzun sürebilecek veri alışverişi başlayacaktır. Senkronizasyon etkinleştirilsin mi?'"), ValueList, 0);
	Else
		ValueList = New ValueList;
		ValueList.Add("Disable", NStr("vi = 'Tắt';
										|ru = 'Выключить';
										|en = 'Disable'; fa = 'غیرفعال';
										|it = 'Disable';
										|pl = 'Disable';
										|tr = 'Devre dışı bırak'"));
		ValueList.Add("DonTTurnItOff", NStr("vi = 'Không tắt';
											|ru = 'Не выключать';
											|en = 'Do not disable'; fa = 'Do not disable';
											|it = 'Do not disable';
											|pl = 'Do not disable';
											|tr = 'Devre dışı bırakma'"));
		
		Notification = New CallbackDescription("AfterClosingQuestionEnableDataExchange", ThisObject);
		ShowQueryBox(Notification, NStr("vi = 'Sau khi tắt đồng bộ, việc trao đổi dữ liệu sẽ không còn được thực hiện và dữ liệu ở chế độ ngoại tuyến có thể không còn cập nhật. Tắt đồng bộ?';
										|ru = 'После выключения синхронизации обмен больше не будет выполняться, и данные в автономном режиме могут стать неактуальными. Выключить синхронизацию?';
										|en = 'After synchronization is disabled, the exchange will no longer be performed, and standalone mode data may become irrelevant. Disable synchronization?'; fa = 'After synchronization is disabled, the exchange will no longer be performed, and standalone mode data may become irrelevant. Disable synchronization?';
										|it = 'After synchronization is disabled, the exchange will no longer be performed, and standalone mode data may become irrelevant. Disable synchronization?';
										|pl = 'After synchronization is disabled, the exchange will no longer be performed, and standalone mode data may become irrelevant. Disable synchronization?';
										|tr = 'Senkronizasyon kapatıldıktan sonra veri alışverişi artık yapılmayacak ve tek başına mod verileri güncelliğini kaybedebilir. Senkronizasyon devre dışı bırakılsın mı?'"), ValueList, 0);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure DocumentsExportStartDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Not ValueIsFilled(Object.DocumentsExportStartDate) Then
		ValueList = New ValueList;
		ValueList.Add("Clear", NStr("vi = 'Xóa';
									|ru = 'Очистить';
									|en = 'Clear'; fa = 'پاک کردن';
									|it = 'Cancellare';
									|pl = 'Clear';
									|tr = 'Temizle'"));
		ValueList.Add("NotClear", NStr("vi = 'Không xóa';
										|ru = 'Не очищать';
										|en = 'Do not clean up'; fa = 'پاک‌سازی نشود';
										|it = 'Non cancellare';
										|pl = 'Nie oczyszczaj';
										|tr = 'Temizlenmesin'"));
		
		Notification = New CallbackDescription("AfterClosingQuestionDateOfStartOfUploadingDocuments", ThisObject);
		ShowQueryBox(Notification, NStr("vi = 'Nếu để trống ngày, thì tất cả chứng từ trong toàn bộ giai đoạn sẽ được kết xuất vào cấu hình độc lập, việc này có thể mất nhiều thời gian. Xóa ngày?';
										|ru = 'Если оставить дату незаполненной, то в автономную конфигурацию будут выгружаться документы за весь период, что может занять продолжительное время. Очистить дату?';
										|en = 'If you leave the date blank, documents for the entire period will be imported to the standalone configuration, which may take a long time. Clear the date?'; fa = 'If you leave the date blank, documents for the entire period will be imported to the standalone configuration, which may take a long time. Clear the date?';
										|it = 'If you leave the date blank, documents for the entire period will be imported to the standalone configuration, which may take a long time. Clear the date?';
										|pl = 'If you leave the date blank, documents for the entire period will be imported to the standalone configuration, which may take a long time. Clear the date?';
										|tr = 'Tarih boş bırakılırsa, tüm dönem için belgeler bağımsız konfigürasyona aktarılacaktır, bu uzun sürebilir. Tarih silinsin mi?'"), ValueList, 0);
	Else
		StartDateOfDocumentUploadCopy = Object.DocumentsExportStartDate;
		Items.DocumentsExportStartDate.ToolTip = StrTemplate(NStr("vi = 'Chỉ những chứng từ có ngày lớn hơn hoặc bằng %1 mới được kết xuất vào chế độ độc lập';
																	|ru = 'В автономный режим будут выгружаться только те документы, дата которых больше или равна  %1';
																	|en = 'Only documents with a date greater than or equal to %1 will be exported to standalone mode'; fa = 'Only documents with a date greater than or equal to %1 will be exported to standalone mode';
																	|it = 'Only documents with a date greater than or equal to %1 will be exported to standalone mode';
																	|pl = 'Only documents with a date greater than or equal to %1 will be exported to standalone mode';
																	|tr = 'Tek başına moda yalnızca tarihi %1''e eşit veya daha büyük olan belgeler aktarılacaktır'"), Format(Object.DocumentsExportStartDate, NStr("vi = 'DLF = D';
																																																					|ru = 'ДЛФ=Д';
																																																					|en = 'DLF=D'; fa = 'DLF=D';
																																																					|it = 'DLF=D';
																																																					|pl = 'DLF=D';
																																																					|tr = 'DLF=D'")));
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterClosingQuestionEnableDataExchange(Result, Var_Parameters) Export
	
	If Result = "Enable" Or Result = "DonTTurnItOff" Then
		Object.EnableDataExchange = True;
	Else
		Object.EnableDataExchange = False;
	EndIf;
	
	Items.DocumentsExportStartDate.Enabled = Not Object.EnableDataExchange;
	
EndProcedure

&AtClient
Procedure AfterClosingQuestionDateOfStartOfUploadingDocuments(Result, Var_Parameters) Export
	
	If Result = "NotClear" Then
		Object.DocumentsExportStartDate = StartDateOfDocumentUploadCopy;
	Else
		StartDateOfDocumentUploadCopy = Object.DocumentsExportStartDate;
	EndIf;
	Items.DocumentsExportStartDate.ToolTip = StrTemplate(NStr("vi = 'Chỉ những chứng từ có ngày lớn hơn hoặc bằng %1 mới được kết xuất vào chế độ độc lập';
																|ru = 'В автономный режим будут выгружаться только те документы, дата которых больше или равна  %1';
																|en = 'Only documents with a date greater than or equal to %1 will be exported to standalone mode'; fa = 'Only documents with a date greater than or equal to %1 will be exported to standalone mode';
																|it = 'Only documents with a date greater than or equal to %1 will be exported to standalone mode';
																|pl = 'Only documents with a date greater than or equal to %1 will be exported to standalone mode';
																|tr = 'Tek başına moda yalnızca tarihi %1''e eşit veya daha büyük olan belgeler aktarılacaktır'"), Format(Object.DocumentsExportStartDate, NStr("vi = 'DLF = D';
																																																				|ru = 'ДЛФ=Д';
																																																				|en = 'DLF=D'; fa = 'DLF=D';
																																																				|it = 'DLF=D';
																																																				|pl = 'DLF=D';
																																																				|tr = 'DLF=D'")));
	
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
	If Item.Name = "sh_ShamsiInput_DocumentsExportStartDate" Then
		DocumentsExportStartDateOnChange(Items.DocumentsExportStartDate);
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
