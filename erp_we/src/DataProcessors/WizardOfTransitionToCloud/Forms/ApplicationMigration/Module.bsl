
#Region Variables

&AtClient
Var CloseOfCourse;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ScheduledJobsServer.OperationsWithExternalResourcesLocked() Then
		Raise NStr("vi = 'Đã phong tỏa làm việc với tất cả các tài nguyên bên ngoài (đồng bộ dữ liệu, gửi thư...).';
					|ru = 'Работа со всеми внешними ресурсами (синхронизация данных, отправка почты и т.п.) заблокирована.';
					|en = 'Scheduled online activities such as data synchronization and emailing are disabled.'; fa = 'Scheduled online activities such as data synchronization and emailing are disabled.';
					|it = 'Lavoro con tutte le risorse esterne (sincronizzazione dei dati, invio di posta, ecc.) bloccato.';
					|pl = 'Praca ze wszystkimi zewnętrznymi zasobami (synchronizacja danych, wysyłanie poczty, itp.) jest zablokowana.';
					|tr = 'Tüm dış kaynaklarla çalışma (veri senkronizasyonu, posta gönderme vb.) engelli.'");
	EndIf;
	
	ServiceAddress = ?(Service = "Other", "", Service);
	
	FillPropertyValues(ThisObject, TransitionState());
	
	If State <> Enums.ApplicationMigrationStates.Running Then
		
		Description = StrTemplate(NStr("vi = '%1 (Di chuyển ứng dụng)';
										|ru = '%1 (Миграция приложения)';
										|en = '%1 (Application migration)'; fa = '%1 (Application migration)';
										|it = '%1 (migrazione applicazione)';
										|pl = '%1 (Migracja aplikacji)';
										|tr = '%1 (Uygulama Geçişi)'"), AppTypesServer.CurrentAppTypePresentation());
		
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Users.Ref AS Ref,
		|	Users.IBUserID
		|FROM
		|	Catalog.Users AS Users";
	Result = Query.Execute().Unload();
	If Result.Count() = 0 Then
		StepsCount = 3;
	ElsIf Result.Count() = 1 And Not ValueIsFilled(Result[0].IBUserID) Then
		StepsCount = 3;
	Else
		StepsCount = 4;
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	OnOpenForm();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Or CloseOfCourse = True Then
		Return;
	EndIf;
	
	If ValueIsFilled(Job) Then
		Cancel = True;
		ShowWarningMonopolyModeIsSet();
		Return;
	EndIf;
	
	If ValueIsFilled(StartDate) Then
		Return;
	EndIf;
	
	Cancel = True;
	StandardProcessing = False;
	CallbackDescription = New CallbackDescription("BeforeClosingAlert", ThisObject);
	QueryText = NStr("vi = 'Đóng trợ giúp?';
					|ru = 'Закрыть помощник?';
					|en = 'Do you want to close the assistant?'; fa = 'Do you want to close the assistant?';
					|it = 'Chiudere assistente?';
					|pl = 'Zamknij asystenta?';
					|tr = 'Sihirbaz kapatılsın mı?'");
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Next(Command)
	
	If Items.Pages.CurrentPage = Items.CreateApplicationPage Then
		NewPage = PageCreateApplicationNext();
	ElsIf Items.Pages.CurrentPage = Items.PageWait Then
		NewPage = WaitingPageNext();
	ElsIf Items.Pages.CurrentPage = Items.ResultPage Then
		NewPage = PageResultNext();
	ElsIf Items.Pages.CurrentPage = Items.ErrorPage Then
		NewPage = ErrorPageNext();
	EndIf;
	
	If NewPage <> Undefined Then
		OpeningPage(NewPage);
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	If Items.Pages.CurrentPage = Items.PageWait Then
	
		CancelTransition();
		DisableServiceStatusUpdateHandler();
		ApplicationParameters.Delete(ApplicationsMigrationClient.NameOfTransitionForm());
		
		OpeningPage(Items.ResultPage);
		
	EndIf;

EndProcedure

&AtClient
Procedure Back(Command)
	
	Page = Items[PagesStack[PagesStack.Count() - 2].Value];
	If Page = Items.PageRegistrationConfirmation Then
		Page = Items[PagesStack[PagesStack.Count() - 3].Value];
	EndIf;
	
	OpeningPage(Page);
	
EndProcedure

#EndRegion

#Region Private

#Region PageHandlers

&AtClient
Procedure OpeningPage(Page)
	
	Items.Next.Visible = True;
	Items.Next.Enabled = True;
	Items.Next.Title = NStr("vi = 'Tiếp theo';
							|ru = 'Далее';
							|en = 'Next'; fa = 'بعدی';
							|it = 'Avanti';
							|pl = 'Dalej';
							|tr = 'İleri'");
	
	Items.Cancel.Visible = False;
	Items.Cancel.Title = NStr("vi = 'Hủy bỏ';
								|ru = 'Отмена';
								|en = 'Cancel'; fa = 'انصراف';
								|it = 'Annulla';
								|pl = 'Anuluj';
								|tr = 'İptal'");
	
	Items.Back.Visible = True;
	
	FoundItem = PagesStack.FindByValue(Page.Name);
	If FoundItem = Undefined Then
		PagesStack.Add(Page.Name);
	Else
		RepeatCount = PagesStack.Count() - PagesStack.IndexOf(FoundItem) - 1;
		For RepeatNumber = 1 To RepeatCount Do
			PagesStack.Delete(PagesStack.Count() - 1);
		EndDo;
	EndIf;
	ItSBackwardsTransition = FoundItem <> Undefined;
	
	If Page = Items.CreateApplicationPage Then
		PageCreateAppOpen(ItSBackwardsTransition);
	ElsIf Page = Items.PageWait Then
		WaitingPageOpening(ItSBackwardsTransition);
	ElsIf Page = Items.ErrorPage Then
		PageErrorOpening(ItSBackwardsTransition);
	ElsIf Page = Items.ResultPage Then
		OpeningResultPage(ItSBackwardsTransition);
	EndIf;
	
	Items.Pages.CurrentPage = Page;
	
EndProcedure

&AtClient
Function PageCreateApplicationNext()
	
	Cancel = False;
	If Not ValueIsFilled(Description) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Tên gọi""';
				|ru = 'Не заполнено поле ""Наименование""';
				|en = 'The Description field is required.'; fa = 'The Description field is required.';
				|it = 'Campo ""Denominazione"" non compilato';
				|pl = 'Pole ""Nazwa"" nie jest wypełnione';
				|tr = '""Ad"" alanı doldurulmadı'"), , "Description", , Cancel);
	EndIf;
	
	If Cancel Then
		Return Undefined;
	EndIf;
	
	BeginSeek();
	
	Return Items.PageWait;
	
EndFunction

&AtClient
Procedure PageCreateAppOpen(ItSBackwardsTransition)
	
	Title = StrTemplate(NStr("vi = 'Bước %1/%1: Tham số tạo mới ứng dụng';
							|ru = 'Шаг %1 из %1: Параметры создания приложения';
							|en = 'Step %1 out of %1: Application creation parameters'; fa = 'Step %1 out of %1: Application creation parameters';
							|it = 'Passaggio %1 di %1: Parametri di creazione dell''applicazione';
							|pl = 'Krok %1 z %1: Parametry utworzenia aplikacji';
							|tr = '%1 adımdan %1 adım: Uygulama oluşturma parametreleri'"), StepsCount);
	Items.Next.Title = NStr("vi = 'Bắt đầu di chuyển';
							|ru = 'Начать миграцию';
							|en = 'Start migration'; fa = 'شروع مهاجرت';
							|it = 'Iniziare migrazione';
							|pl = 'Rozpocznij migrację';
							|tr = 'Geçişi başlat'");
	Items.Back.Visible = False;
	
	If Not ValueIsFilled(Description) Then
		Description = "";
	EndIf;
	
EndProcedure

&AtClient
Function WaitingPageNext()
	
	Job = RunMonopolyCompletion();
	
	If ValueIsFilled(Job) Then
		BlockEntireInterface();
		ShowWarningMonopolyModeIsSet();
	Else
		Text = NStr("vi = 'Không thể thiết lập chế độ độc quyền, cần kết thúc phiên làm việc của tất cả người sử dụng.';
					|ru = 'Не удалось установить монопольный режим, необходимо завершение сеансов всех пользователей.';
					|en = 'Cannot set the exclusive mode, close the sessions of all users.'; fa = 'Cannot set the exclusive mode, close the sessions of all users.';
					|it = 'Impossibile stabilire la modalità esclusiva, è necessario completare le sessioni di tutti gli utenti.';
					|pl = 'Nie można ustawić trybu wyłączności, musisz ukończyć sesje wszystkich użytkowników.';
					|tr = 'Tekli kullanıcı mod kurulamıyor, tüm kullanıcı oturumların kapatılması gerekiyor.'");
		ShowMessageBox(, Text);
	EndIf;

	Return Undefined;
	
EndFunction

&AtClient
Procedure WaitingPageOpening(ItSBackwardsTransition)
	
	ApplicationParameters[ApplicationsMigrationClient.NameOfTransitionForm()] = ThisObject;
	
	Items.Next.Visible = ExclusiveModeRequired;
	Items.Next.Title = NStr("vi = 'Hoàn thành quá trình di chuyển';
							|ru = 'Завершить миграцию';
							|en = 'Complete migration'; fa = 'تکمیل مهاجرت';
							|it = 'Completare migrazione';
							|pl = 'Zakończ migrację';
							|tr = 'Taşımayı tamamla'");
	Items.Next.Enabled = Not ValueIsFilled(Job);
	Title = ?(ValueIsFilled(Job), 
		NStr("vi = 'Hoàn thành quá trình di chuyển...';
			|ru = 'Завершение миграции...';
			|en = 'Completing migration…'; fa = 'Completing migration…';
			|it = 'Completamento della migrazione...';
			|pl = 'Zakończenie migracji...';
			|tr = 'Taşımanın tamamlanması...'"), 
		NStr("vi = 'Đang di chuyển...';
			|ru = 'Выполняется миграция...';
			|en = 'Migrating…'; fa = 'Migrating…';
			|it = 'Migrazione in corso...';
			|pl = 'Migrowanie w toku...';
			|tr = 'Taşınma yürütülüyor...'"));
	Items.Cancel.Visible = True;
	Items.Back.Visible = False;
	
	LF = Chars.LF;
	Tab = Chars.Tab;
	
	Rows = New Array;
	Rows.Add(NStr("vi = 'Địa chỉ dịch vụ';
					|ru = 'Адрес сервиса';
					|en = 'Service address'; fa = 'آدرس سرویس';
					|it = 'Indirizzo del servizio di assistenza';
					|pl = 'Adres serwisu';
					|tr = 'Hizmet adresi'") + ": ");
	Rows.Add(New FormattedString(ServiceAddress, , , , ServiceAddress));
	Rows.Add(LF);
	Rows.Add(StrTemplate(NStr("vi = 'Mã thuê bao: %1';
								|ru = 'Код абонента: %1';
								|en = 'Subscriber code: %1'; fa = 'Subscriber code: %1';
								|it = 'Codice abbonamento: %1';
								|pl = 'Kod subskrybenta: %1';
								|tr = 'Abone kodu: %1'"), SubscriberCode) + LF);
	Rows.Add(StrTemplate(NStr("vi = 'Mã ứng dụng: %1';
								|ru = 'Код приложения: %1';
								|en = 'Application code: %1'; fa = 'Application code: %1';
								|it = 'Codice app: %1';
								|pl = 'Kod aplikacji: %1';
								|tr = 'Uygulama kodu: %1'"), ApplicationCode) + LF);
	Rows.Add(NStr("vi = 'Liên hệ của doanh nghiệp dịch vụ';
					|ru = 'Контакты обслуживающей организации';
					|en = 'Service company contacts'; fa = 'Service company contacts';
					|it = 'Contatti dell''organizzazione di servizio';
					|pl = 'Kontakty firmy świadczenia usług';
					|tr = 'Hizmet veren iş yerinin iletişim bilgileri'") + ":" + LF);
	Rows.Add(Tab);
	Rows.Add(Tab + StrTemplate(NStr("vi = 'e-mail: %1';
									|ru = 'e-mail: %1';
									|en = 'e-mail: %1'; fa = 'e-mail: %1';
									|it = 'e-mail: %1';
									|pl = 'e-mail: %1';
									|tr = 'e-mail: %1'"), ServiceCompanyEmail) + LF);
	Rows.Add(Tab);
	Rows.Add(Tab + StrTemplate(NStr("vi = 'đt.: %1';
									|ru = 'тел.: %1';
									|en = 'phone: %1'; fa = 'phone: %1';
									|it = 'Tel.: %1';
									|pl = 'tel.: %1';
									|tr = 'tel.: %1'"), ServiceCompanyPhoneNumber) + LF);
	
	Items.InformationDecoration.Title = New FormattedString(Rows);
	
	EnableServiceStatusUpdateHandler();
	
EndProcedure

&AtClient
Function PageResultNext()
	
	ClearUploadState();
	Close();
	Return Undefined;
	
EndFunction

&AtClient
Procedure OpeningResultPage(ItSBackwardsTransition)
	
	Title = NStr("vi = 'Kết quả di chuyển';
				|ru = 'Результат миграции';
				|en = 'Migration result'; fa = 'Migration result';
				|it = 'Risultato migrazione';
				|pl = 'Wynik migracji';
				|tr = 'Taşıma sonucu'");
	
	Items.Next.Title = NStr("vi = 'Đồng ý';
							|ru = 'Готово';
							|en = 'Done'; fa = 'انجام شد';
							|it = 'Fine';
							|pl = 'Done';
							|tr = 'Bitiş'");
	Items.Cancel.Visible = False;
	Items.Back.Visible = False;
	
	Items.DecorationRef.Visible = ValueIsFilled(ApplicationURL);
	If ValueIsFilled(ApplicationURL) Then
		Items.DecorationRef.Title = New FormattedString(ApplicationURL, , , , ApplicationURL);
	EndIf;
	
EndProcedure

&AtClient
Function ErrorPageNext()
	
	ClearUploadState();
	ApplicationParameters.Delete(ApplicationsMigrationClient.NameOfTransitionForm());
	Close();
	Return Undefined;
	
EndFunction

&AtClient
Procedure PageErrorOpening(ItSBackwardsTransition)
	
	Title = NStr("vi = 'Lỗi di chuyển';
				|ru = 'Ошибка миграции';
				|en = 'Migration error'; fa = 'Migration error';
				|it = 'Errore di migrazione';
				|pl = 'Błąd migracji';
				|tr = 'Taşıma hatası'");
	
	Items.Next.Title = NStr("vi = 'Đồng ý';
							|ru = 'Готово';
							|en = 'Done'; fa = 'انجام شد';
							|it = 'Fine';
							|pl = 'Done';
							|tr = 'Bitiş'");
	Items.Cancel.Visible = False;
	Items.Back.Visible = False;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure BeginSeek()
	
	ApplicationsMigration.ValidateExchangePlanContent();
	
	ApplicationData = ApplicationsMigration.CreateMigrationApplication(
		ThisObject, Description, SessionTimeZone(), UsersRights, RecoveryExtensions);
	ApplicationCode = ApplicationData.Code;
	
	ExportUserSettings = New Map;
	For Each UserRights_ In UsersRights Do
		If ValueIsFilled(UserRights_.User) Then
			ExportUserSettings.Insert(UserRights_.User, UserRights_.Login);
		EndIf;
	EndDo;
	
	CompleteMigrationAutomatically = MigrationCompletionOption = 0;
	
	ServiceOrganizationData = ApplicationsMigration.ServiceOrganizationData(ThisObject);
	
	ServiceCompanyEmail = ServiceOrganizationData.Email;
	ServiceCompanyPhoneNumber = ServiceOrganizationData.Phone;
	
	AdditionalProperties = New Structure;
	AdditionalProperties.Insert("ServiceAddress", ServiceAddress);
	AdditionalProperties.Insert("ServiceCompanyEmail", ServiceCompanyEmail);
	AdditionalProperties.Insert("ServiceCompanyPhoneNumber", ServiceCompanyPhoneNumber);
	AdditionalProperties.Insert("SubscriberCode", SubscriberCode);
	AdditionalProperties.Insert("ApplicationCode", ApplicationCode);
	
	ApplicationsMigration.BeginUnload(
		ApplicationData.ApplicationURL, 
		ApplicationData.Login, 
		ApplicationData.Password, 
		ExportUserSettings, 
		CompleteMigrationAutomatically, 
		AdditionalProperties);
	
	FillPropertyValues(ThisObject, TransitionState());
	
EndProcedure

&AtServer
Procedure CancelTransition()
	
	ApplicationsMigration.CancelUpload();
	DisableExclusiveMode_();
	Job = Undefined;
	ApplicationURL = "";
	CompletedOn = CurrentSessionDate();
	Comment = NStr("vi = 'Đã hủy quá trình chuyển sang dịch vụ';
					|ru = 'Переход в сервис отменен';
					|en = 'Cloud migration canceled'; fa = 'Cloud migration canceled';
					|it = 'Passaggio al servizio annullato';
					|pl = 'Przejście do usługi anulowane';
					|tr = 'Servise geçiş iptal edildi'");
	
EndProcedure

&AtServerNoContext
Function TransitionState()
	
	TransitionState = ApplicationsMigration.ExportState();
	TransitionState.Insert("TimeLeft", NStr("vi = 'Đang tính...';
											|ru = 'Рассчитывается...';
											|en = 'Calculating…'; fa = 'Calculating…';
											|it = 'Sta calcolando...';
											|pl = 'Calculating…';
											|tr = 'Hesaplanıyor...'"));
	
	If (TransitionState.State = Enums.ApplicationMigrationStates.Running 
			Or TransitionState.State = Enums.ApplicationMigrationStates.PendingImport)
		And TransitionState.SentMessageNumber >= 3 
		And TransitionState.ObjectsImported <> 0 Then
		
		RemainingTime = (CurrentUniversalDate() - TransitionState.StartDate) / 
			TransitionState.ObjectsImported * TransitionState.ImportObjects;
		
		If RemainingTime <= 180 Then
			TransitionState.TimeLeft = NStr("vi = 'Một vài phút';
											|ru = 'Несколько минут';
											|en = 'Several minutes'; fa = 'Several minutes';
											|it = 'Qualche minuto';
											|pl = 'Kilka minut';
											|tr = 'Birkaç dakika'");
		ElsIf RemainingTime <= 3600 Then
			TransitionState.TimeLeft = StrTemplate(NStr("vi = '~ %1 phút.';
														|ru = '~ %1 мин.';
														|en = '~ %1 min.'; fa = '~ %1 min.';
														|it = '~ %1 min.';
														|pl = '~ %1 min.';
														|tr = '~ %1 dak.'"), Round(RemainingTime / 60));
		Else
			TransitionState.TimeLeft = StrTemplate(NStr("vi = '~ %1 giờ';
														|ru = '~ %1 ч.';
														|en = '~ %1 h.'; fa = '~ %1 h.';
														|it = '~ %1 h.';
														|pl = '~ %1 g.';
														|tr = '~ %1 s.'"), Round(RemainingTime / 3600, 1));
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(TransitionState.StartDate) Then
		TransitionState.StartDate = ToLocalTime(TransitionState.StartDate, SessionTimeZone());
	EndIf;
	
	If ValueIsFilled(TransitionState.CompletedOn) Then
		TransitionState.CompletedOn = ToLocalTime(TransitionState.CompletedOn, SessionTimeZone());
	EndIf;
	
	TransitionState.Insert("Progress", 0);
	If TransitionState.ObjectsImported <> 0 Then
		TransitionState.Insert("Progress", TransitionState.ObjectsImported * 100 / 
			(TransitionState.ImportObjects + TransitionState.ObjectsImported));
	EndIf;
	
	TransitionState.Insert("MessagesSentProcessedText", StrTemplate(NStr("vi = '%1 / %2';
																		|ru = '%1 / %2';
																		|en = '%1 / %2'; fa = '%1 / %2';
																		|it = '%1 / %2';
																		|pl = '%1 / %2';
																		|tr = '%1 / %2'"), 
		TransitionState.SentMessageNumber, TransitionState.ReceivedMessageNumber));
	TransitionState.Insert("ObjectsExportedImportedText", StrTemplate(NStr("vi = '%1 / %2';
																			|ru = '%1 / %2';
																			|en = '%1 / %2'; fa = '%1 / %2';
																			|it = '%1 / %2';
																			|pl = '%1 / %2';
																			|tr = '%1 / %2'"), 
		TransitionState.ObjectsExported, TransitionState.ObjectsImported));
	TransitionState.Insert("LeftToExportImportText", StrTemplate(NStr("vi = '%1 / %2';
																		|ru = '%1 / %2';
																		|en = '%1 / %2'; fa = '%1 / %2';
																		|it = '%1 / %2';
																		|pl = '%1 / %2';
																		|tr = '%1 / %2'"), 
		TransitionState.ObjectsChanged, TransitionState.ImportObjects));
	
	Return TransitionState;
	
EndFunction

&AtClient
Procedure UpdatingTransitionStatus() Export
	
	PastRequiresMonopolyRegime = ExclusiveModeRequired;
	
	FillPropertyValues(ThisObject, TransitionState());
	
	If ValueIsFilled(CompletedOn) Then
		
		If ValueIsFilled(Job) Then
			If DisableExclusiveMode_() Then
				Job = Undefined;
				DisableServiceStatusUpdateHandler();
				ApplicationParameters.Delete(ApplicationsMigrationClient.NameOfTransitionForm());
			EndIf;
		EndIf;
		
		If State = PredefinedValue("Enum.ApplicationMigrationStates.OperationFailed") Then
			NewPage = Items.ErrorPage;
		Else
			NewPage = Items.ResultPage;
		EndIf;
		
		OpeningPage(NewPage);
		
		If Not IsOpen() Then
			Open();
		EndIf;
		
	Else
		
		Items.Next.Visible = ExclusiveModeRequired;
		If ValueIsFilled(Job) Then
			// Checking a running task
			Job = RunMonopolyCompletion();
		ElsIf ExclusiveModeRequired And CompleteMigrationAutomatically Then
			// An attempt to set an exclusive mode and, if successful, you need to block the entire interface 
			// so that the user cannot change the data.
			Job = RunMonopolyCompletion();
			If ValueIsFilled(Job) Then
				BlockEntireInterface();
			EndIf;
		ElsIf ExclusiveModeRequired And Not PastRequiresMonopolyRegime And Not CompleteMigrationAutomatically And Not IsOpen() Then
			// The data is almost unloaded, it remains to set the exclusive mode,
			// To do this, you need to show the form so that the user clicks the button.
			Open();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearUploadState()
	
	InformationRegisters.ApplicationsMigrationExportState.CreateRecordSet().Write();
	
EndProcedure

&AtClient
Procedure BeforeClosingAlert(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		CloseOfCourse = True;
		Close();
	EndIf;
	
EndProcedure

&AtServerNoContext
Function RunMonopolyCompletion()
	
	Try
		SetExclusiveMode(True);
	Except
		Return Undefined;
	EndTry;
	
	Filter = New Structure("Key, State", "ApplicationsMigrationExport", BackgroundJobState.Active);
	RunningJobs = BackgroundJobs.GetBackgroundJobs(Filter);
	If RunningJobs.Count() = 0 Then
		JobParameters = New Array;
		JobParameters.Add(True);
		BackgroundJob = BackgroundJobs.Execute(ApplicationsMigration.MethodNameExportJob(),
			JobParameters, "ApplicationsMigrationExport");
		Return BackgroundJob.UUID;
	Else
		Return RunningJobs[0].UUID;
	EndIf;
	
EndFunction

&AtServerNoContext
Function DisableExclusiveMode_()
	
	Try
		SetExclusiveMode(False);
	Except
		Return False;
	EndTry;

	Return True;
	
EndFunction

&AtClient
Procedure OnOpenForm(OnStart = False) Export
	
	If State = PredefinedValue("Enum.ApplicationMigrationStates.OperationSuccessful") Then
		NewPage = Items.ResultPage;
	ElsIf State = PredefinedValue("Enum.ApplicationMigrationStates.OperationFailed") Then
		NewPage = Items.ErrorPage;
	ElsIf State = PredefinedValue("Enum.ApplicationMigrationStates.Running")
		Or State = PredefinedValue("Enum.ApplicationMigrationStates.PendingImport") Then
		NewPage = Items.PageWait;
	Else
		NewPage = Items.CreateApplicationPage;
	EndIf;
	
	OpeningPage(NewPage);
	
	If OnStart 
		And (ValueIsFilled(CompletedOn) Or ExclusiveModeRequired) 
		And Not IsOpen() Then
		Open();
	EndIf;
	
EndProcedure

&AtClient
Procedure BlockEntireInterface()
	
	If IsOpen() Then
		OpeningPage(Items.Pages.CurrentPage);
	Else
		Open();
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowWarningMonopolyModeIsSet()
	
	Text = NStr("vi = 'Đã thiết lập chế độ độc quyền, không đóng ứng dụng trước khi kết thúc di chuyển.';
				|ru = 'Установлен монопольный режим, не закрывайте приложение до окончания миграции.';
				|en = 'Exclusive mode is selected, do not close the application until migration is complete.'; fa = 'Exclusive mode is selected, do not close the application until migration is complete.';
				|it = 'Impostata modalità esclusiva, non chiudere l''applicazione fino alla fine della migrazione.';
				|pl = 'Tryb wyłączności jest ustawiony, nie zamykaj aplikacji do końca migracji.';
				|tr = 'Tekli kullanıcı modu ayarlandı, geçiş tamamlanana kadar uygulamayı kapatmayın.'");
	ShowMessageBox(, Text);
	
EndProcedure

#EndRegion

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
