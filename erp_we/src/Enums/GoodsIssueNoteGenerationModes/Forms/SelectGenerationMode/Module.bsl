#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	GoodsIssueNoteGenerationMode = Parameters.GoodsIssueNoteGenerationMode;
	
	Items.TheModeOfGeneratingSpendingOrdersAutomatically.ToolTip =
		Enums.GoodsIssueNoteGenerationModes.FormationModeHint(Enums.GoodsIssueNoteGenerationModes.Automatically);
	Items.ModeOfFormationOfExpenseOrdersByTheManager.ToolTip =
		Enums.GoodsIssueNoteGenerationModes.FormationModeHint(Enums.GoodsIssueNoteGenerationModes.ByManager);
	Items.TheModeOfFormationOfExpenditureOrdersByTheStorekeeper.ToolTip =
		Enums.GoodsIssueNoteGenerationModes.FormationModeHint(Enums.GoodsIssueNoteGenerationModes.ByWarehouseman);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	If GoodsIssueNoteGenerationMode = PredefinedValue("Enum.GoodsIssueNoteGenerationModes.Automatically") Then
		
		QueryText = NStr("vi = 'Sau khi thay đổi chế độ sang ""Tự động"" đối với tất cả kho hai pha sẽ:
			| - bật sử dụng trạng thái phiếu xuất kho;
			| - đã khởi động tạo phiếu xuất kho ở chế độ nền.
			|Có thể kiểm tra việc thực hiện nhiệm vụ nền ""Đặt trình tự tạo lại phiếu xuất kho"" tại chỗ làm việc Quản trị - Hỗ trợ và bảo trì - Nhiệm vụ nền và nhiệm vụ thường kỳ.
			|Tiếp tục?';
			|ru = 'После изменения режима на ""Автоматически"" для всех ордерных складов будет:
			| - включено использование статусов расходных ордеров;
			| - запущено фоновое формирование расходных ордеров.
			|Проверить выполнение фонового задания ""Формирование очереди переоформления расходных ордеров"" можно в рабочем месте Администрирование - Поддержка и обслуживание - Регламентные и фоновые задания.
			|Продолжить?';
			|en = 'After switching the mode to ""Automatically"", the following operations will be executed for all warehouses when warehouse management is enabled:
			| - Enable usage of goods issue note statuses;
			| - Start background generation of goods issue notes.
			|You can check execution of the ""Generation of queue of goods issue note reregistration"" background job at workplace in Settings - Support and service - Scheduled and background jobs.
			|Continue?'; fa = 'After switching the mode to ""Automatically"", the following operations will be executed for all warehouses when warehouse management is enabled:
			| - Enable usage of goods issue note statuses;
			| - Start background generation of goods issue notes.
			|You can check execution of the ""Generation of queue of goods issue note reregistration"" background job at workplace in Settings - Support and service - Scheduled and background jobs.
			|Continue?';
			|it = 'Dopo il cambiamento della modalità in ""Automatica"" per tutti i magazzini dei mandati sarà:
			| - attivato l''utilizzo degli status dei mandati di pagamento;
			|avviata la generazione in background dei mandati di pagamento.
			|Potete controllare l''esecuzione del task in background ""Generazione di coda di riemissione dei mandati di pagamento"" nella postazione di lavoro Amministrazione - Supporto e manutenzione - Task di regolamentazione e di background.
			|Continuare?';
			|pl = 'Po zmianie trybu na ""Automatycznie"" dla wszystkich magazynów zamówień będzie:
			| - włączone stosowanie statusów zleceń wydania;
			| - uruchomione w tle kształtowanie zleceń wydania.
			|Sprawdzić wykonanie w tle zadania ""Kształtowanie kolejki ponownego sporządzenia zleceń wydania"" w miejscu pracy Administrowanie - Pomoc i obsługa - Zadania reglamentowane i zadania w tle.
			|Kontynuować?';
			|tr = 'Tüm ambarlar için modu ""Otomatik"" olarak değiştirdikten sonra, ambar çıkış fişleri durumlarının kullanımı şu şekilde olacaktır:
			| -gider emri durumlarının kullanımı bağlı;
			| - ambar çıkış fişlerinin arka planda oluşturulması başlatıldı.
			|""Ambar çıkış fişlerinin yeniden düzenlenmesi için kuyruğun oluşturulması"" arka plan görevinin yürütülmesini Yönetim - Destek ve Bakım - Programlı iş ve arka plan görevleri çalışma alanından kontrol edilebilinir.
			|Devam edilsin mi?'");
		
		CallbackDescription = New CallbackDescription("OKCompletion", ThisObject);
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.OKCancel);
		
	Else
		NotifyChoice(GoodsIssueNoteGenerationMode);
	EndIf;
EndProcedure

&AtClient
Procedure OKCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.OK Then
		NotifyChoice(GoodsIssueNoteGenerationMode);
	EndIf;
		
EndProcedure

&AtClient
Procedure Cancel(Command)
	Close();
EndProcedure

#EndRegion

