
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
	
		Return;
	
	EndIf;
	
	FullName = FormAttributeToValue("Object").Metadata().FullName();
	
	// ABC/XYZ Classification Parameters
	UseRevenueClassification = Constants.UseABCXYZClassificationOfPartnersByRevenue.Get();
	UseGrossProfitClassification = Constants.UseABCXYZClassificationOfPartnersByGrossProfit.Get();
	UseClassificationByNumberOfSales = Constants.UseABCXYZClassificationOfPartnersByNumberOfSales.Get();
	
	// ABC classification
	ABCLassificationPeriod = Constants.PeriodOfABCClassificationOfPartners.Get();
	NumberOfABCLassificationPeriods = Constants.NumberOfPeriodsOfABCClassificationOfPartners.Get();
	
	// XYZ classification
	XYZClassificationPeriod = Constants.PeriodOfXYZClassificationOfPartners.Get();
	NumberOfXYZClassificationPeriods = Constants.NumberOfPeriodsOfXYZClassificationOfPartners.Get();
	XyzclassificationSubperiod = Constants.SubperiodOfXYZClassificationOfPartners.Get();
	
	// Label design colors
	InformationTextColor = StyleColors.NoteText;
	ErrorInformationTextColor = StyleColors.ErrorNoteText;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Items.FeaturePages.PagesRepresentation = FormPagesRepresentation.None;
	
	UpdateFormDisplay();
	UpdateDescriptions();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DecorationFullFrequentlyUsedFeaturesClick(Item)
	
	FullFunctionality = Not FullFunctionality;
	UpdateFormDisplay();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PerformAbcxyzclassificationFrequentlyUsedFeatures(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.Classification.CustomerClassification.Command.PerformAbcxyzclassificationFrequentlyUsedFeatures");
	
	ShowUserNotification(NStr("vi = 'Phân loại khách hàng';
								|ru = 'Классификация клиентов';
								|en = 'Customer classification'; fa = 'طبقه‌بندی مشتریان';
								|it = 'Classificazione dei clienti';
								|pl = 'Klasyfikacja klientów';
								|tr = 'Müşteri sınıflandırması'"),, NStr("vi = 'Đang thực hiện phân loại ABC/XYZ...';
																		|ru = 'Выполняется ABC/XYZ классификация...';
																		|en = 'Executing ABC/XYZ classification ...'; fa = 'Executing ABC/XYZ classification ...';
																		|it = 'Classificazione ABC/XYZ in corso';
																		|pl = 'Wykonywanie klasyfikacji ABC/XYZ...';
																		|tr = 'ABC/XYZ sınıflandırması gerçekleştirilmektedir...'"), PictureLib.Information32);
	
	PerformABCXYZClassificationOnServer();
	
	ShowUserNotification(NStr("vi = 'Phân loại khách hàng';
								|ru = 'Классификация клиентов';
								|en = 'Customer classification'; fa = 'طبقه‌بندی مشتریان';
								|it = 'Classificazione dei clienti';
								|pl = 'Klasyfikacja klientów';
								|tr = 'Müşteri sınıflandırması'"),, NStr("vi = 'Đã thực hiện phân loại ABC/XYZ!';
																		|ru = 'Выполнена ABC/XYZ классификация!';
																		|en = 'ABC/XYZ classification is complete.'; fa = 'ABC/XYZ classification is complete.';
																		|it = 'Classificazione ABC/XYZ effettuata!';
																		|pl = 'Wykonano klasyfikację ABC/XYZ!';
																		|tr = 'ABC/XYZ sınıflandırması gerçekleştirildi!'"), PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure ToPerformAmsclassificationFull(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.Classification.CustomerClassification.Command.ToPerformAmsclassificationFull");
	
	ShowUserNotification(NStr("vi = 'Phân loại khách hàng';
								|ru = 'Классификация клиентов';
								|en = 'Customer classification'; fa = 'طبقه‌بندی مشتریان';
								|it = 'Classificazione dei clienti';
								|pl = 'Klasyfikacja klientów';
								|tr = 'Müşteri sınıflandırması'"),, NStr("vi = 'Đang thực hiện phân loại ABC...';
																		|ru = 'Выполняется ABC классификация...';
																		|en = 'Executing ABC classification...'; fa = 'Executing ABC classification...';
																		|it = 'Classificazione ABC in corso...';
																		|pl = 'Wykonywanie klasyfikacji ABC...';
																		|tr = 'ABC/XYZ sınıflandırması gerçekleştirilmektedir...'"), PictureLib.Information32);
	
	PerformABCClassificationOnServer();
	
	ShowUserNotification(NStr("vi = 'Phân loại khách hàng';
								|ru = 'Классификация клиентов';
								|en = 'Customer classification'; fa = 'طبقه‌بندی مشتریان';
								|it = 'Classificazione dei clienti';
								|pl = 'Klasyfikacja klientów';
								|tr = 'Müşteri sınıflandırması'"),, NStr("vi = 'Đã thực hiện phân loại ABC!';
																		|ru = 'Выполнена ABC классификация!';
																		|en = 'ABC classification is complete.'; fa = 'ABC classification is complete.';
																		|it = 'Classificazione ABC effettuata!';
																		|pl = 'Wykonana klasyfikacja ABC!';
																		|tr = 'ABC sınıflandırması gerçekleştirildi!'"), PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure PerformXYZClassificationFullFeatures(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.Classification.CustomerClassification.Command.PerformXYZClassificationFullFeatures");
	
	ShowUserNotification(NStr("vi = 'Phân loại khách hàng';
								|ru = 'Классификация клиентов';
								|en = 'Customer classification'; fa = 'طبقه‌بندی مشتریان';
								|it = 'Classificazione dei clienti';
								|pl = 'Klasyfikacja klientów';
								|tr = 'Müşteri sınıflandırması'"),, NStr("vi = 'Đang thực hiện phân loại XYZ...';
																		|ru = 'Выполняется XYZ классификация...';
																		|en = 'Executing XYZ classification...'; fa = 'Executing XYZ classification...';
																		|it = 'Classificazione XYZ in corso';
																		|pl = 'Wykonywanie klasyfikacji XYZ...';
																		|tr = 'XYZ sınıflandırması gerçekleştirilmektedir...'"), PictureLib.Information32);
	
	PerformXYZClassificationOnServer();
	
	ShowUserNotification(NStr("vi = 'Phân loại khách hàng';
								|ru = 'Классификация клиентов';
								|en = 'Customer classification'; fa = 'طبقه‌بندی مشتریان';
								|it = 'Classificazione dei clienti';
								|pl = 'Klasyfikacja klientów';
								|tr = 'Müşteri sınıflandırması'"),, NStr("vi = 'Đã thực hiện phân loại XYZ!';
																		|ru = 'Выполнена XYZ классификация!';
																		|en = 'XYZ classification is complete.'; fa = 'XYZ classification is complete.';
																		|it = 'Classificazione XYZ effettuata!';
																		|pl = 'Wykonana klasyfikacja XYZ!';
																		|tr = 'XYZ sınıflandırması gerçekleştirildi!'"), PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure SettingUpAbcxyzclassingFullFeatures(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.Classification.CustomerClassification.Command.SettingUpAbcxyzclassingFullFeatures");
	
	ReturnCode = Undefined;

	
	OpenForm(FullName + ".Form.CustomizeCustomerClassificationSettings",,,,,, New CallbackDescription("SettingUpAbcxyzclassificationFullFeaturesCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SettingUpAbcxyzclassificationFullFeaturesCompletion(Result, AdditionalParameters) Export
    
    ReturnCode = Result;
    
    If TypeOf(ReturnCode) = Type("Structure") Then
        
        UseRevenueClassification = ReturnCode.UseRevenueClassification;
        UseGrossProfitClassification = ReturnCode.UseGrossProfitClassification;
        UseClassificationByNumberOfSales = ReturnCode.UseClassificationByNumberOfSales;
        ABCLassificationPeriod = ReturnCode.ABCLassificationPeriod;
        NumberOfABCLassificationPeriods = ReturnCode.NumberOfABCLassificationPeriods;
        XYZClassificationPeriod = ReturnCode.XYZClassificationPeriod;
        NumberOfXYZClassificationPeriods = ReturnCode.NumberOfXYZClassificationPeriods;
        XyzclassificationSubperiod = ReturnCode.XyzclassificationSubperiod;
        
        UpdateFormDisplay();
        UpdateDescriptions();
        
    EndIf;

EndProcedure

&AtClient
Procedure ClearAVCLassificationFullFeatures(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.Classification.CustomerClassification.Command.ClearAVCLassificationFullFeatures");
	
	ReturnCode = Undefined;

	
	ShowQueryBox(New CallbackDescription("ClearABCClassificationFullFeaturesCompletion", ThisObject), NStr("vi = 'Toàn bộ thông tin về phân loại ABC khách hàng sẽ bị xóa. Tiếp tục?';
																											|ru = 'Вся информация об ABC классификации клиентов будет очищена. Продолжить?';
																											|en = 'Customer ABC classification will be cleared. Do you want to continue?'; fa = 'Customer ABC classification will be cleared. Do you want to continue?';
																											|it = 'Tutte le informazioni sulla classificazione clienti ABC saranno eliminate. Continuare?';
																											|pl = 'Wszystkie informacje o klasyfikacji klientów ABC zostaną wyczyszczone. Kontynuować?';
																											|tr = 'ABC müşteri sınıflandırması ile ilgili tüm bilgiler temizlenecektir. Devam edilsin mi?'"), QuestionDialogMode.OKCancel);
	
EndProcedure

&AtClient
Procedure ClearABCClassificationFullFeaturesCompletion(QuestionResult, AdditionalParameters) Export
    
    ReturnCode = QuestionResult;
    
    If ReturnCode = DialogReturnCode.OK Then
        
        ShowUserNotification(NStr("vi = 'Phân loại khách hàng';
									|ru = 'Классификация клиентов';
									|en = 'Customer classification'; fa = 'طبقه‌بندی مشتریان';
									|it = 'Classificazione dei clienti';
									|pl = 'Klasyfikacja klientów';
									|tr = 'Müşteri sınıflandırması'"),, NStr("vi = 'Đang xóa kết quả phân loại ABC...';
																			|ru = 'Выполняется очистка ABC классификации...';
																			|en = 'Clearing ABC classification...'; fa = 'Clearing ABC classification...';
																			|it = 'Pulizia della classificazione ABC in corso...';
																			|pl = 'Czyszczenie klasyfikacji ABC w toku...';
																			|tr = 'ABC sınıflandırmasının temizliği gerçekleştirilmektedir...'"), PictureLib.Information32);
        
        ClearABCClassificationOnServer();
        
        ShowUserNotification(NStr("vi = 'Phân loại khách hàng';
									|ru = 'Классификация клиентов';
									|en = 'Customer classification'; fa = 'طبقه‌بندی مشتریان';
									|it = 'Classificazione dei clienti';
									|pl = 'Klasyfikacja klientów';
									|tr = 'Müşteri sınıflandırması'"),, NStr("vi = 'Đã xóa kết quả phân loại ABC!';
																			|ru = 'Выполнена очистка ABC классификации!';
																			|en = 'ABC classification is cleared.'; fa = 'ABC classification is cleared.';
																			|it = 'Pulizia della classificazione ABC effettuata!';
																			|pl = 'Oczyszczona klasyfikacja ABC!';
																			|tr = 'ABC sınıflandırmasının temizliği gerçekleştirildi!'"), PictureLib.Information32);
        
    EndIf;

EndProcedure

&AtClient
Procedure ClearXYZClassificationFullFeatures(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.Classification.CustomerClassification.Command.ClearXYZClassificationFullFeatures");
	
	ReturnCode = Undefined;

	
	ShowQueryBox(New CallbackDescription("ClearXYZClassificationFullFeaturesCompletion", ThisObject), NStr("vi = 'Toàn bộ thông tin về phân loại XYZ khách hàng sẽ bị xóa. Tiếp tục?';
																											|ru = 'Вся информация об XYZ классификации клиентов будет очищена. Продолжить?';
																											|en = 'Customer XYZ classification will be cleared. Do you want to continue?'; fa = 'Customer XYZ classification will be cleared. Do you want to continue?';
																											|it = 'Tutte le informazioni sulla classificazione clienti XYZ saranno eliminate. Continuare?';
																											|pl = 'Wszystkie informacje o klasyfikacji klientów XYZ zostaną wyczyszczone. Kontynuować?';
																											|tr = 'XYZ müşteri sınıflandırması ile ilgili tüm bilgiler temizlenecektir. Devam edilsin mi?'"), QuestionDialogMode.OKCancel);
	
EndProcedure

&AtClient
Procedure ClearXYZClassificationFullFeaturesCompletion(QuestionResult, AdditionalParameters) Export
    
    ReturnCode = QuestionResult;
    
    If ReturnCode = DialogReturnCode.OK Then
        
        ShowUserNotification(NStr("vi = 'Phân loại khách hàng';
									|ru = 'Классификация клиентов';
									|en = 'Customer classification'; fa = 'طبقه‌بندی مشتریان';
									|it = 'Classificazione dei clienti';
									|pl = 'Klasyfikacja klientów';
									|tr = 'Müşteri sınıflandırması'"),, NStr("vi = 'Đang thực hiện xóa kết quả phân loại XYZ...';
																			|ru = 'Выполняется очистка XYZ классификации...';
																			|en = 'Clearing XYZ classification...'; fa = 'Clearing XYZ classification...';
																			|it = 'Pulizia della classificazione XYZ in corso...';
																			|pl = 'Czyszczenie klasyfikacji XYZ w toku...';
																			|tr = 'XYZ sınıflandırmasının temizliği gerçekleştirilmektedir...'"), PictureLib.Information32);
        
        ClearXYZClassificationOnServer();
        
        ShowUserNotification(NStr("vi = 'Phân loại khách hàng';
									|ru = 'Классификация клиентов';
									|en = 'Customer classification'; fa = 'طبقه‌بندی مشتریان';
									|it = 'Classificazione dei clienti';
									|pl = 'Klasyfikacja klientów';
									|tr = 'Müşteri sınıflandırması'"),, NStr("vi = 'Đã xóa kết quả phân loại XYZ!';
																			|ru = 'Выполнена очистка XYZ классификации!';
																			|en = 'XYZ classification is cleared.'; fa = 'XYZ classification is cleared.';
																			|it = 'Pulizia della classificazione XYZ effettuata!';
																			|pl = 'Wykonano czyszczenie klasyfikacji XYZ!';
																			|tr = 'XYZ sınıflandırmasının temizliği gerçekleştirildi!'"), PictureLib.Information32);
        
    EndIf;

EndProcedure

#EndRegion

#Region Private

#Region Other

&AtClient
Procedure UpdateDescriptions()
	
	ABCDescriptionFrequentlyUsedFeatures = StrTemplate(NStr("vi = 'Phân loại ABC theo dữ liệu cho kỳ: %1.';
															|ru = 'ABC классификация по данным за период: %1.';
															|en = 'ABC classification according to the data over a period: %1.'; fa = 'ABC classification according to the data over a period: %1.';
															|it = 'Classificazione ABC per dati per il periodo: %1.';
															|pl = 'Klasyfikacja danych ABC dla okresu: %1.';
															|tr = 'Dönem verilerine göre ABC sınıflandırması: %1.'"),
		SupplyClientServer.SettingDetails(ABCLassificationPeriod, NumberOfABCLassificationPeriods));
	XYZDescriptionFrequentlyUsedFeatures = StrTemplate(NStr("vi = 'Phân loại XYZ theo dữ liệu cho kỳ: %1.';
															|ru = 'XYZ классификация по данным за период: %1.';
															|en = 'XYZ classification according to the data over a period: %1.'; fa = 'XYZ classification according to the data over a period: %1.';
															|it = 'Classificazione XYZ per dati per il periodo: %1.';
															|pl = 'Klasyfikacja danych XYZ dla okresu: %1.';
															|tr = 'Dönem verilerine göre XYZ sınıflandırması: %1.'"),
		SupplyClientServer.SettingDetails(XYZClassificationPeriod, NumberOfXYZClassificationPeriods, XyzclassificationSubperiod));
	ABCDescriptionFullFeatures = StrTemplate(NStr("vi = 'Phân loại ABC cho tất cả các kỳ theo dữ liệu cho kỳ: %1.';
													|ru = 'ABC классификация за все периоды по данным за период: %1.';
													|en = 'ABC classification for all periods according to the data over a period: %1.'; fa = 'ABC classification for all periods according to the data over a period: %1.';
													|it = 'Classificazione ABC per tutti i periodi per dati per il periodo: %1.';
													|pl = 'Klasyfikacja ABC dla wszystkich okresów według danych okresu: %1.';
													|tr = 'Dönem verilerine göre tüm dönemler için ABC sınıflandırması: %1.'"),
		SupplyClientServer.SettingDetails(ABCLassificationPeriod, NumberOfABCLassificationPeriods));
	XYZDescriptionFullFeatures = StrTemplate(NStr("vi = 'Phân loại XYZ trong tất cả các giai đoạn theo dữ liệu trong kỳ: %1.';
													|ru = 'XYZ классификация за все периоды по данным за период: %1.';
													|en = 'XYZ classification for all periods according to the data over a period: %1.'; fa = 'XYZ classification for all periods according to the data over a period: %1.';
													|it = 'Classificazione XYZ per tutti i periodi per dati per il periodo: %1.';
													|pl = 'Klasyfikacja XYZ dla wszystkich okresów według danych okresu: %1.';
													|tr = 'Dönem verilerine göre tüm dönemler için XYZ sınıflandırması: %1.'"),
		SupplyClientServer.SettingDetails(XYZClassificationPeriod, NumberOfXYZClassificationPeriods, XyzclassificationSubperiod));
	
	// Frequently used features
	If UseRevenueClassification
		Or UseGrossProfitClassification
		Or UseClassificationByNumberOfSales Then
	
		Items.DecorationAbcxyzclassificationDescriptionFrequentlyUsedFeatures.Title =
			ABCDescriptionFrequentlyUsedFeatures + " " + XYZDescriptionFrequentlyUsedFeatures;
			
		Items.DecorationAbcxyzclassificationDescriptionFrequentlyUsedFeatures.TextColor = InformationTextColor;
		
	Else
		
		Items.DecorationAbcxyzclassificationDescriptionFrequentlyUsedFeatures.Title =
			NStr("vi = 'Hãy chuyển đến tính năng đầy đủ và trong tùy chỉnh hãy thiết lập tham số cần thực hiện phân loại.';
				|ru = 'Перейдите к полным возможностям и в настройке установите параметры, по которым необходимо выполнять классификацию.';
				|en = 'Go to full functionality. In the settings set parameters that will be used for classification.'; fa = 'Go to full functionality. In the settings set parameters that will be used for classification.';
				|it = 'Andare alle funzionalità complete e nelle impostazioni, impostare i parametri con cui si vuole eseguire la classificazione.';
				|pl = 'Przejdź do pełnych możliwości i ustawień, ustaw parametry, według których chcesz dokonać klasyfikacji.';
				|tr = 'Tam olanaklara gidin ve ayarlarda sınıflandırmayı gerçekleştirmek istediğiniz parametreleri yapılandırın.'");
			
		Items.DecorationAbcxyzclassificationDescriptionFrequentlyUsedFeatures.TextColor = ErrorInformationTextColor;
		
	EndIf;
	
	// Full opportunity
	If UseRevenueClassification
		Or UseGrossProfitClassification
		Or UseClassificationByNumberOfSales Then
	
		Items.TheDecorationsAmsclassificationDescriptionFull.Title = ABCDescriptionFullFeatures;
		Items.DecorationXYZClassificationDescriptionFullFeatures.Title = XYZDescriptionFullFeatures;
		
		Items.TheDecorationsAmsclassificationDescriptionFull.TextColor = InformationTextColor;
		Items.DecorationXYZClassificationDescriptionFullFeatures.TextColor = InformationTextColor;
		
	Else
		
		Items.TheDecorationsAmsclassificationDescriptionFull.Title = NStr("vi = 'Hãy chuyển đến tùy chỉnh và thiết lập tham số cần thực hiện phân loại.';
																			|ru = 'Перейдите к настройке и установите параметры, по которым необходимо выполнять классификацию.';
																			|en = 'Go to settings and set parameters that will be used for classification.'; fa = 'Go to settings and set parameters that will be used for classification.';
																			|it = 'Passare alle impostazioni e impostare i parametri in base ai quale è necessario eseguire la classificazione.';
																			|pl = 'Przejdź do ustawienia i ustaw parametry, według których chcesz dokonać klasyfikacji.';
																			|tr = 'Ayarlara gidin ve sınıflandırmayı gerçekleştirmek istediğiniz parametreleri yapılandırın.'");
		Items.DecorationXYZClassificationDescriptionFullFeatures.Title = NStr("vi = 'Hãy chuyển đến tùy chỉnh và thiết lập tham số cần thực hiện phân loại.';
																				|ru = 'Перейдите к настройке и установите параметры, по которым необходимо выполнять классификацию.';
																				|en = 'Go to settings and set parameters that will be used for classification.'; fa = 'Go to settings and set parameters that will be used for classification.';
																				|it = 'Passare alle impostazioni e impostare i parametri in base ai quale è necessario eseguire la classificazione.';
																				|pl = 'Przejdź do ustawienia i ustaw parametry, według których chcesz dokonać klasyfikacji.';
																				|tr = 'Ayarlara gidin ve sınıflandırmayı gerçekleştirmek istediğiniz parametreleri yapılandırın.'");
		
		Items.TheDecorationsAmsclassificationDescriptionFull.TextColor = ErrorInformationTextColor;
		Items.DecorationXYZClassificationDescriptionFullFeatures.TextColor = ErrorInformationTextColor;
		
	EndIf;
	
	Items.DecorationClearAbclassificationDescriptionFullFeatures.Title = NStr("vi = 'Xóa kết quả phân loại ABC trong tất cả các kỳ.';
																				|ru = 'Очистить ABC классификацию за все периоды.';
																				|en = 'Clear the ABC classification for all periods.'; fa = 'Clear the ABC classification for all periods.';
																				|it = 'Cancellare la classificazione ABC per tutti i periodi.';
																				|pl = 'Wyczyść klasyfikację ABC dla wszystkich okresów.';
																				|tr = 'Tüm dönemler için öğe ABC sınıflandırmasını temizle.'");
	Items.DecorationClearXYZClassificationDescriptionFullFeatures.Title = NStr("vi = 'Xóa kết quả phân loại XYZ trong tất cả các kỳ.';
																				|ru = 'Очистить XYZ классификацию за все периоды.';
																				|en = 'Clear the XYZ classification for all periods.'; fa = 'Clear the XYZ classification for all periods.';
																				|it = 'Cancellare la classificazione XYZ per tutti i periodi.';
																				|pl = 'Wyczyść klasyfikację XYZ dla wszystkich okresów.';
																				|tr = 'Tüm dönemler için öğe XYZ sınıflandırmasını temizle.'");
	
EndProcedure

&AtClient
Procedure UpdateFormDisplay()
	
	If FullFunctionality Then
		
		// Switching to full features
		Items.FeaturePages.CurrentPage = Items.FullFeaturesPage;
		
		// Changing the title of the form and the title of the decoration
		Title = NStr("vi = 'Phân loại khách hàng - tính năng đầy đủ';
					|ru = 'Классификация клиентов - полные возможности';
					|en = 'Customer classification - full functions'; fa = 'Customer classification - full functions';
					|it = 'Classificazione dei clienti - piena funzionalità';
					|pl = 'Klasyfikacja klientów - pełne możliwości';
					|tr = 'Müşteri sınıflandırması - tam olanaklar'");
		Items.DecorationFullFrequentlyUsedFeatures.Title = NStr("vi = 'Tính năng thường sử dụng';
																|ru = 'Часто используемые возможности';
																|en = 'Frequently used features'; fa = 'قابلیت‌های پرکاربرد';
																|it = 'Funzionalità più utilizzate';
																|pl = 'Często używane możliwości';
																|tr = 'Sık kullanılan olanaklar'");
		
		// Availability of ABC classification execution
		Items.ToPerformAmsclassificationFull.Enabled = UseRevenueClassification
																			Or UseGrossProfitClassification
																			Or UseClassificationByNumberOfSales;
																			
		// Availability of XYZ classification execution
		Items.PerformXYZClassificationFullFeatures.Enabled = UseRevenueClassification
																			Or UseGrossProfitClassification
																			Or UseClassificationByNumberOfSales;
		
	Else
		
		 // Switching to frequently used features
		Items.FeaturePages.CurrentPage = Items.APageOfFrequentlyUsedFeatures;
		
		// Changing the title of the form and the title of the decoration
		Title = NStr("vi = 'Phân loại khách hàng - tính năng thường sử dụng';
					|ru = 'Классификация клиентов - часто используемые возможности';
					|en = 'Customer classification - frequently used functions'; fa = 'Customer classification - frequently used functions';
					|it = 'Classificazione dei clienti - funzionalità più utilizzate';
					|pl = 'Klasyfikacja klientów - często używane funkcje';
					|tr = 'Müşteri sınıflandırması - sık kullanılan olanaklar'");
		Items.DecorationFullFrequentlyUsedFeatures.Title = NStr("vi = 'Tính năng đầy đủ';
																|ru = 'Полные возможности';
																|en = 'Full functionality'; fa = 'عملکرد کامل';
																|it = 'Funzionalità complete';
																|pl = 'Pełne możliwości';
																|tr = 'Tam olanaklar'");
		
		// Availability of ABC/XYZ classification execution
		Items.PerformAbcxyzclassificationFrequentlyUsedFeatures.Enabled = UseRevenueClassification
																						Or UseGrossProfitClassification
																						Or UseClassificationByNumberOfSales;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure PerformABCXYZClassificationOnServer()
	
	Classification.PerformABCClassificationOfPartners();
	Classification.PerformXYZClassificationOfPartners();
	
EndProcedure

&AtServer
Procedure PerformABCClassificationOnServer()
	
	SetPrivilegedMode(True);

	Query = New Query(
	"SELECT TOP 1
	|	RevenueAndCOGS.Period AS Period
	|FROM
	|	AccumulationRegister.RevenueAndCOGS AS RevenueAndCOGS
	|
	|ORDER BY
	|	Period");
	
	QueryResult = Query.Execute();
	
	SetPrivilegedMode(False);
	
	If QueryResult.IsEmpty() Then
		
		Return;
		
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	ClassificationDate = TMCommonUseClientServer.ExtendedPeriod(Selection.Period, ABCLassificationPeriod, 0).EndDate + 1;
    MaximumClassificationDate = TMCommonUseClientServer.ExtendedPeriod(CurrentSessionDate(), ABCLassificationPeriod, -1).EndDate + 1;
	
	While ClassificationDate <= MaximumClassificationDate Do
		
		Classification.PerformABCClassificationOfPartners(ClassificationDate);
		ClassificationDate = TMCommonUseClientServer.CalculatePeriodEndDate(ClassificationDate, ABCLassificationPeriod, 1) + 1;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure PerformXYZClassificationOnServer()
	
	SetPrivilegedMode(True);

	Query = New Query(
	"SELECT TOP 1
	|	RevenueAndCOGS.Period AS Period
	|FROM
	|	AccumulationRegister.RevenueAndCOGS AS RevenueAndCOGS
	|
	|ORDER BY
	|	Period");
	
	QueryResult = Query.Execute();
	
	SetPrivilegedMode(False);
	
	If QueryResult.IsEmpty() Then
		
		Return;
		
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	ClassificationDate = TMCommonUseClientServer.ExtendedPeriod(Selection.Period, XYZClassificationPeriod, 0).EndDate + 1;
    MaximumClassificationDate = TMCommonUseClientServer.ExtendedPeriod(CurrentSessionDate(), XYZClassificationPeriod, -1).EndDate + 1;
	
	While ClassificationDate <= MaximumClassificationDate Do
		
		Classification.PerformXYZClassificationOfPartners(ClassificationDate);
		ClassificationDate = TMCommonUseClientServer.CalculatePeriodEndDate(ClassificationDate, XYZClassificationPeriod, 1) + 1;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ClearABCClassificationOnServer()
	
	InformationRegisters.ABCXYZCustomerClassification.ClearABCClassification();
	
EndProcedure

&AtServer
Procedure ClearXYZClassificationOnServer()
	
	InformationRegisters.ABCXYZCustomerClassification.ClearXYZClassification();
	
EndProcedure

#EndRegion

#EndRegion
