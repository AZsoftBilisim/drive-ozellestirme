///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Procedures for logging the calculation performed by the mechanisms
//	- batch accounting version 2.2
//	- cost calculation.
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

#Region LoggingCalculation


// Creates a structure for the description of the calculation Protocol.
// 
// Returns:
// 	Structure - LongDesc:
// * Stages - See CostCalculationProtocol.InitializeCalculationStepDescriptionTable
// * FormedRegisteredRecords - Structure -
// * WritingRegisterRecords - Structure -
// * NumberOfRegisteredRecordedCalls - Number -
// * RecordingErrors - Array -
// * MovementErrors - Array -
// * CalculationErrors - Map -
// * Duration - Undefined -
// * EndTime - Undefined -
// * BeginTime - Number -
// * StartDate - Date -
// * Id - String -
// * ExecutingCodeSnippet - Array -
//
Function InitializeCalculationProtocol() Export
	
	CalculationProtocol = New Structure;
	
	// General information about the calculation.
	CalculationProtocol.Insert("Id",  TrimAll(New UUID));;
	CalculationProtocol.Insert("StartDate",     CurrentSessionDate());
	CalculationProtocol.Insert("BeginTime",    CurrentUniversalDateInMilliseconds());
	CalculationProtocol.Insert("EndTime", Undefined);
	CalculationProtocol.Insert("Duration",   Undefined);
	CalculationProtocol.Insert("CalculationIsCompleted", False);
	
	// Error information.
	CalculationProtocol.Insert("CalculationErrors",  New Map); // types of errors that occurred during the calculation
	CalculationProtocol.Insert("MovementErrors", New Array); // error texts about incorrect registrars
	CalculationProtocol.Insert("RecordingErrors",   New Array); // texts of errors that occurred when recording movements
	
	// Information about movements recorded in the IB.
	CalculationProtocol.Insert("WritingRegisterRecords", New Structure);
	CalculationProtocol.Insert("NumberOfRegisteredRecordedCalls", 0);
	
	// To calculate the total number of movements generated in the cache (cumulative total).
	CalculationProtocol.Insert("FormedRegisteredRecords", New Structure);
	
	CalculationProtocol.Insert("Stages", InitializeCalculationStepDescriptionTable());
	
	Return CalculationProtocol;
	 
EndFunction


// Creates a table describing the calculation stage.
// 
// Returns:
// 	ValueTable - LongDesc:
// * PresentationStage - String - 
// * StageLevel - Number - 
// * StartDate - Date - 
// * BeginTime - Number - 
// * EndTime - Number -
// * FormedRegisteredRecords - Structure -
// * GeneratedTTStrings - Structure - 
// * TemporaryTable - Structure -
// * CodeExecutionMeasurements - Structure - 
// * ErrorInformation_ - Map - 
// * DataVolume - Number -
// * AdditionalInformation - Array -
// 
Function InitializeCalculationStepDescriptionTable() Export
	
	Stages = New ValueTable;
	Stages.Columns.Add("PresentationStage");
	Stages.Columns.Add("StageLevel");
	Stages.Columns.Add("StartDate");
	Stages.Columns.Add("BeginTime");
	Stages.Columns.Add("EndTime");
	Stages.Columns.Add("FormedRegisteredRecords"); // for a specific stage, only for modified registers
	Stages.Columns.Add("GeneratedTTStrings"); // by a specific stage, only by modified temporary tables
	Stages.Columns.Add("TemporaryTable"); // Structure(the name of the temporary table is an Array(Structure(number of records, time of formation)))
	Stages.Columns.Add("CodeExecutionMeasurements"); // Structure(code identifier - Array(Structure(explanation, execution time)))
	Stages.Columns.Add("ErrorInformation_"); // array of rows grouped by error types
	Stages.Columns.Add("DataVolume"); // the amount of data to measure performance
	Stages.Columns.Add("AdditionalInformation"); // array of arbitrary strings
	
	Return Stages;
	
EndFunction

// Initializes auxiliary data for maintaining the calculation Protocol.
// You don't need to call it explicitly - it is called at the beginning of the first stage.
//
Procedure CalculationStart(CalculationParameters) Export
	
	// Let's make a record of the beginning of the stage in the LR.
	MarkInLog(CalculationParameters, "InitializeCalculationParameters");
	
	// Let's add the protocol to the general calculation parameters.
	CalculationParameters.Insert("CalculationProtocol", InitializeCalculationProtocol());
	
	// Let's add performance measurement parameters to the general calculation parameters.
	StartTimeMeasurement(CalculationParameters);
	
EndProcedure

// Completes logging and generates a text-based calculation Protocol.
// 
// Parameters:
//  CalculationParameters - Structure - Calculation parameters
Procedure CalculationEnd(CalculationParameters) Export
	
	CalculationProtocol = CalculationParameters.CalculationProtocol; // See CostCalculationProtocol.InitializeCalculationProtocol 
	
	// If there was no explicit announcement of the end of the previous calculation stage, then we will close it due to the end of the calculation.
	EndOfCalculationStage(CalculationParameters);
	
	// Let's determine the presence of errors in the calculation.
	ThereWereMovementErrors = (CalculationProtocol.MovementErrors.Count() > 0); // problems with the Registrar
	ThereWereRecordingErrors   = (CalculationProtocol.RecordingErrors.Count() > 0);   // Registered Records problems
	
	CalculationProtocol.CalculationIsCompleted = True;
	
	GeneratePaymentProtocol(CalculationParameters);
	
#Region SavingCalculationErrors
	
	// The calculation error register records information only about those calculation options
	// that affect the determination of the closing status of the month in terms of calculating batches/cost.
	
	CalculationOption = Undefined;
	
	If CalculationParameters.BatchAccountingVersion22 Then // batch accounting version 2.2
		If CalculationParameters.CalculationOption = Enums.LotAndCostCalculationOptions.LotsAndCost
		 Or CalculationParameters.CalculationOption = Enums.LotAndCostCalculationOptions.ActualCostCalculation Then
			CalculationOption = CalculationParameters.CalculationOption;
		EndIf;
	Else // batch accounting version 2.1 (or not used at all)
		If CalculationParameters.CalculationOption = Enums.LotAndCostCalculationOptions.ActualCostCalculation Then
			CalculationOption = CalculationParameters.CalculationOption;
		EndIf;
	EndIf;
	
	If ValueIsFilled(CalculationOption) Then		
		
		// Create entries in the error register for each organization/error.
		// At the same time, it is necessary to clear all previous errors for this period and organization.
		
		For Each CurrentCompany In CalculationParameters.CompanyArray Do
			
			ErrorRecords = InformationRegisters.LotAndCostCalculationErrors.CreateRecordSet();
			
			ErrorRecords.Filter.Period.Set(CalculationParameters.PayrollPeriod.BeginOfPeriod);
			ErrorRecords.Filter.Organization.Set(CurrentCompany);
			
			For Each CurrentError In CalculationProtocol.CalculationErrors Do
				
				ErrorRecording = ErrorRecords.Add();
				
				ErrorRecording.Period 	 			= CalculationParameters.PayrollPeriod.BeginOfPeriod;
				ErrorRecording.Organization 			= CurrentCompany;
				ErrorRecording.CalculationOption	 		= CalculationOption;
				ErrorRecording.ErrorType				= CurrentError.Key;
				ErrorRecording.UniqueProtocolID	= CalculationProtocol.Id;
				
			EndDo;
			
			ErrorRecords.Write(True);
			
		EndDo;
		
	EndIf;
	
#EndRegion
	
	EndTimeMeasurement(CalculationParameters);
	
	CalculationParameters.Delete("CalculationProtocol");
	
	If ThereWereMovementErrors Or ThereWereRecordingErrors Then
		
		ErrorText =
			CostCalculationAppliedAlgorithms.ServiceSymbol_ProblemAlreadyRegistered()
		 	+ NStr("vi = 'Đã kết thúc tính giá vốn một cách bất thường.
				|Chi tiết xem trong Nhật ký sự kiện';
				|ru = 'Расчет себестоимости завершился аварийно.
				|Подробнее см. в Журнале регистрации';
				|en = 'Cost calculation aborted.
				|See details in the event log.'; fa = 'Cost calculation aborted.
				|See details in the event log.';
				|it = 'Il calcolo del costo di produzione è stato terminato in modo anomalo.
				|Si vedano i dettagli nel registro di log';
				|pl = 'Kalkulacja kosztów własnych zakończyła się nieprawidłowo.
				|Aby uzyskać więcej informacji, zobacz Dziennik rejestracji';
				|tr = 'Maliyet hesaplaması bir kaza ile sona erdi.
				|Daha fazla ayrıntı için kayıt defterine bak'", Common.DefaultLanguageCode());
		
		Raise ErrorText; // The movements were formed/recorded incorrectly - the calculation was not performed
		
	EndIf;
	
EndProcedure

// Generates the calculation Protocol.
//
Procedure GeneratePaymentProtocol(CalculationParameters)
	
	CalculationProtocol = CalculationParameters.CalculationProtocol; // See CostCalculationProtocol.InitializeCalculationProtocol 
	
	// If there was no explicit announcement of the end of the previous calculation stage, then we will close it due to the end of the calculation.
	EndOfCalculationStage(CalculationParameters);
	
	CalculationProtocol.EndTime = CurrentUniversalDateInMilliseconds();
	CalculationProtocol.Duration   = RuntimePresentation(CalculationProtocol);
	
	// Let's determine the presence of errors in the calculation.
	HadErrors 		   = (CalculationProtocol.CalculationErrors.Count() > 0);
	ThereWereMovementErrors = (CalculationProtocol.MovementErrors.Count() > 0); // problems with the Registrar
	ThereWereRecordingErrors   = (CalculationProtocol.RecordingErrors.Count() > 0);   // Registered Records problems
	
	// Let's form the text of the protocol.
	Protocol = New TextDocument;
	
#Region ProtocolHeader
	
	If Not CalculationProtocol.CalculationIsCompleted Or HadErrors Then
		Protocol.AddLine(NStr("vi = 'CHÚ Ý!';
								|ru = 'ВНИМАНИЕ !';
								|en = 'WARNING!'; fa = 'WARNING!';
								|it = 'ATTENZIONE !';
								|pl = 'UWAGA !';
								|tr = 'DİKKAT !'", Common.DefaultLanguageCode()));
	EndIf;
	
	If Not CalculationProtocol.CalculationIsCompleted Then
		Protocol.AddLine(NStr("vi = 'Đây là giao thức tính toán trung gian - vẫn chưa hoàn tất hạch toán!';
								|ru = 'Это промежуточный протокол расчета - расчет еще не завершен!';
								|en = 'This is an intermediate calculation log - the calculation is not yet complete!'; fa = 'This is an intermediate calculation log - the calculation is not yet complete!';
								|it = 'Questo è il protocollo di calcolo intermedio: il calcolo non è ancora stato completato!';
								|pl = 'To jest pośredni protokół obliczenia - obliczenie nie jest zakończone!';
								|tr = 'Bu bir ara hesaplama protokolüdür - hesaplama henüz tamamlanmadı!'", Common.DefaultLanguageCode()));
		Protocol.AddLine("");
	EndIf;

	If HadErrors Then
		
		Protocol.AddLine(PresentationOfCalculationErrors(
			CalculationProtocol,
			NStr("vi = 'Trong quá trình tính toán đã chẩn đoán lỗi:';
				|ru = 'В ходе расчета были диагностированы ошибки:';
				|en = 'Errors were found during calculation:'; fa = 'Errors were found during calculation:';
				|it = 'Durante il calcolo sono stati diagnosticati degli errori:';
				|pl = 'Błędy zostały zdiagnozowane podczas obliczeń:';
				|tr = 'Hesaplama sırasında hatalar tespit edildi:'", Common.DefaultLanguageCode()),
			Chars.LF + "	- "));
		Protocol.AddLine(NStr("vi = 'Có thể tìm thấy mô tả chi tiết lỗi (Ctrl-F) trong nội dung giao thức theo ký tự ""!"".';
								|ru = 'Подробное описание ошибок можно найти (Ctrl-F) в тексте протокола по символу ""!"".';
								|en = 'You can find (Ctrl+F) detailed error description by the ""!"" character in the protocol text.'; fa = 'You can find (Ctrl+F) detailed error description by the ""!"" character in the protocol text.';
								|it = 'Una descrizione completa degli errori può essere trovata (Ctrl-F) nel testo del protocollo secondo il simbolo ""!"".';
								|pl = 'Szczegółowy opis błędów można znaleźć (Ctrl-F) w tekście protokołu za pomocą symbolu ""!"".';
								|tr = 'Hataların detaylı ayrıntısı protokol metninde ""!"" ile bulunabilir (Ctrl-F).'", Common.DefaultLanguageCode()));
		
		If ThereWereMovementErrors Or ThereWereRecordingErrors Then
			Protocol.AddLine(NStr("vi = 'Đã tính ngẫu nhiên.';
									|ru = 'Расчет завершился аварийно.';
									|en = 'Calculation aborted.'; fa = 'Calculation aborted.';
									|it = 'Il calcolo è stato terminato in modo anomalo.';
									|pl = 'Obliczenia zakończyły się nieprawidłowo.';
									|tr = 'Hesaplama bir kazayla sonuçlandı.'", Common.DefaultLanguageCode()));
		EndIf;
		
		Protocol.AddLine("");
		
	EndIf;
	
	SystemInfo = New SystemInfo;
	
	Protocol.AddLine(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Giao thức tính toán (tên định danh %1)';
			|ru = 'Протокол расчета (идентификатор %1)';
			|en = 'Calculation protocol (ID %1)'; fa = 'Calculation protocol (ID %1)';
			|it = 'Protocollo di calcolo (identificatore %1)';
			|pl = 'Protokół obliczeniowy (identyfikator %1)';
			|tr = 'Hesaplama protokolü (tanımlayıcı %1)'", Common.DefaultLanguageCode()),
		CalculationProtocol.Id));
	Protocol.AddLine(NStr("vi = 'Nền tảng:';
							|ru = 'Платформа:';
							|en = 'Platform:'; fa = 'Platform:';
							|it = 'Piattaforma:';
							|pl = 'Platform:';
							|tr = 'Platform:'", Common.DefaultLanguageCode()) + " " + SystemInfo.AppVersion);
	Protocol.AddLine(NStr("vi = 'Cấu hình:';
							|ru = 'Конфигурация:';
							|en = 'Configuration:'; fa = 'Configuration:';
							|it = 'Configurazione:';
							|pl = 'Configuration:';
							|tr = 'Konfigürasyon:'", Common.DefaultLanguageCode()) + " " + ValuePresentation(Metadata.Name)
		+ ", " + NStr("vi = 'phiên bản:';
						|ru = 'версия:';
						|en = 'version:'; fa = 'version:';
						|it = 'versione:';
						|pl = 'version:';
						|tr = 'sürüm:'", Common.DefaultLanguageCode()) + " " + ValuePresentation(Metadata.Version));
	Protocol.AddLine(NStr("vi = 'Cơ sở thông tin:';
							|ru = 'Информационная база:';
							|en = 'Infobase:'; fa = 'Infobase:';
							|it = 'Database:';
							|pl = 'Baza informacyjna:';
							|tr = 'Infobase:'", Common.DefaultLanguageCode()) + " " 
		+ ValuePresentation(CalculationParameters.IBConnectionString));
	Protocol.AddLine(NStr("vi = 'Bắt đầu tính toán:';
							|ru = 'Начало расчета:';
							|en = 'Calculation start:'; fa = 'Calculation start:';
							|it = 'Inizio del calcolo:';
							|pl = 'Początek obliczenia:';
							|tr = 'Hesaplama başlangıcı:'", Common.DefaultLanguageCode()) + " " + ValuePresentation(CalculationProtocol.StartDate)
		+ ", " + NStr("vi = 'thời lượng:';
						|ru = 'длительность:';
						|en = 'duration:'; fa = 'duration:';
						|it = 'durata:';
						|pl = 'duration:';
						|tr = 'süre:'", Common.DefaultLanguageCode()) + " " + ValuePresentation(CalculationProtocol.Duration));
	Protocol.AddLine(NStr("vi = 'Nơi gọi ra tính toán:';
							|ru = 'Место вызова расчета:';
							|en = 'Calculation call place:'; fa = 'Calculation call place:';
							|it = 'Luogo di chiamata del calcolo:';
							|pl = 'Miejsce wywołania obliczania:';
							|tr = 'Hesaplama çağrısının yeri:'", Common.DefaultLanguageCode()) + " " 
		+ ValuePresentation(CalculationParameters.PlaceOfCalculationCall));
	
	Protocol.AddLine("");
	Protocol.AddLine(NStr("vi = 'Phương án tính toán:';
							|ru = 'Вариант расчета:';
							|en = 'Calculation option:'; fa = 'Calculation option:';
							|it = 'Variante di calcolo:';
							|pl = 'Wariant obliczania:';
							|tr = 'Hesaplama seçeneği:'", Common.DefaultLanguageCode()) + " " 
		+ ValuePresentation(CalculationParameters.CalculationOption));
	Protocol.AddLine(NStr("vi = 'Chế độ đóng tháng:';
							|ru = 'Режим закрытия месяца:';
							|en = 'Month-end closing mode:'; fa = 'Month-end closing mode:';
							|it = 'Modalità di chiusura del mese:';
							|pl = 'Tryb zamknięcia miesiąca:';
							|tr = 'Ay sonu kapanışı modu:'", Common.DefaultLanguageCode()) + " " 
		+ ValuePresentation(CalculationParameters.MonthEndClosingMode));
	Protocol.AddLine(NStr("vi = 'Kỳ thanh toán:';
							|ru = 'Период расчета:';
							|en = 'Calculation period:'; fa = 'Calculation period:';
							|it = 'Periodo del calcolo:';
							|pl = 'Okres obliczania:';
							|tr = 'Hesaplama dönemi:'", Common.DefaultLanguageCode()) + " "
		+ PresentationOfCalculationPeriod(CalculationParameters));
	
	If Not CalculationProtocol.CalculationIsCompleted And CalculationParameters.Property("CopyArrayOfOrganizations") Then
		OrganizationsForProtocol = CalculationParameters.CopyArrayOfOrganizations;
	ElsIf CalculationParameters.CalculationOption = Enums.LotAndCostCalculationOptions.LotsAndCost Then
		OrganizationsForProtocol = CalculationParameters.CompanyArray;
	Else		
		OrganizationsForProtocol = CalculationParameters.OrganizationsWithCostRegisteredRecords;
	EndIf;
	
	Protocol.AddLine(NStr("vi = 'Doanh nghiệp để tính:';
							|ru = 'Организации для расчета:';
							|en = 'Companies for calculation:'; fa = 'Companies for calculation:';
							|it = 'Organizzazione per il calcolo:';
							|pl = 'Firma dla obliczania:';
							|tr = 'Hesaplama için iş yeri:'", Common.DefaultLanguageCode()));
	For Each CurrentCompany In OrganizationsForProtocol Do
		Protocol.AddLine("	- "	+ ValuePresentation(CurrentCompany)
			+ ", " + NStr("vi = 'phương pháp đánh giá giá trị:';
							|ru = 'метод оценки стоимости:';
							|en = 'cost evaluation method:'; fa = 'cost evaluation method:';
							|it = 'metodo di classificazione del costo:';
							|pl = 'metoda oceny wartości:';
							|tr = 'maliyet değerleme yöntemi:'", Common.DefaultLanguageCode()) + " " 
			+ ?(CalculationParameters.Property("AccountingPolicies"), ValuePresentation(CalculationParameters.AccountingPolicies.ValuationMethods[CurrentCompany]), ""));
	EndDo;
	
	If ValueIsFilled(CalculationParameters.DocumentsChanged) Then
		Protocol.AddLine(NStr("vi = 'Đã thay đổi chứng từ trong CSDL sau phép tính lần trước:';
								|ru = 'Изменено документов в ИБ после прошлого расчета:';
								|en = 'Changed documents in the infobase after the previous calculation:'; fa = 'Changed documents in the infobase after the previous calculation:';
								|it = 'Documenti modificati nel DB dopo lo scorso calcolo:';
								|pl = 'Zmieniono dokumenty w IB po ostatnich obliczeniach:';
								|tr = 'Son hesaplamadan sonra Infobase''de belgeler değiştirildi:'", Common.DefaultLanguageCode()) + " "
			+ ValuePresentation(CalculationParameters.DocumentsChanged));
	EndIf;
	
	Protocol.AddLine("");
	ExtensionNames = "";
	Try
		For Each CurrentExtension In ConfigurationExtensions.Get() Do
			
			If CurrentExtension.Active Then
				ExtensionNames = ExtensionNames + ?(ExtensionNames = "", "", Chars.LF) + "	- "
					+ CurrentExtension.Name + " (" + CurrentExtension.UUID + ")";
			EndIf;
			
		EndDo;
	Except
		ExtensionNames = "";
	EndTry;
	
	ExtensionNames = NStr("vi = 'Phần mở rộng cấu hình đang hoạt động:';
							|ru = 'Активные расширения конфигурации:';
							|en = 'Active configuration extensions:'; fa = 'Active configuration extensions:';
							|it = 'Estensioni attive della configurazione:';
							|pl = 'Aktywne rozszerzenia konfiguracji:';
							|tr = 'Etkin konfigürasyon uzantıları:'")
		+ ?(ValueIsFilled(ExtensionNames), Chars.LF + ExtensionNames, " " + NStr("vi = 'không có';
																				|ru = 'отсутствуют';
																				|en = 'missing'; fa = 'missing';
																				|it = 'mancano';
																				|pl = 'brak';
																				|tr = 'eksik'"));
	Protocol.AddLine(ExtensionNames);
	
	Protocol.AddLine("");
	Protocol.AddLine(ProtocolPartSeparator());
	Protocol.AddLine(NStr("vi = 'Tùy chọn chức năng ảnh hưởng đến kết quả tính toán:';
							|ru = 'Функциональные опции, влияющие на результат расчета:';
							|en = 'Functional options which influence the calculation result:'; fa = 'Functional options which influence the calculation result:';
							|it = 'Opzioni funzionali che influiscono sul risultato del calcolo:';
							|pl = 'Opcje funkcjonalne wpływające na wynik obliczeń:';
							|tr = 'Hesaplamanın sonucunu etkileyen işlevsel seçenekler:'", Common.DefaultLanguageCode()));
	
	For Each CurFO In CalculationParameters.FederalDistrict Do
		FODetails = CostCalculationAppliedAlgorithms.DescriptionOfConstantOrFunctionOption(CurFO.Key);
		Protocol.AddLine("	- " + FODetails.Metadata.Presentation() + ": "	+ ValuePresentation(CurFO.Value, True));
	EndDo;
	
	// We will output the technological parameters of the calculation.
	Protocol.AddLine("");
	Protocol.AddLine(ProtocolPartSeparator());
	Protocol.AddLine("Technological_ parameters calculation:");
	Protocol.AddLine("");
	
	// We will display information about the general parameters of the month closing.
	ParametersDetails 		= MonthEndTransactionsServer.DescriptionOfTechnologicalParametersForClosingMonth();
	DescriptionOfParameterGroups = MonthEndTransactionsServer.DescriptionOfGroupsOfParametersForMonthClosingOperation();
	ParameterValues 		= MonthEndTransactionsServer.GeneralParametersForClosingMonth();
	
	For Each CurrentGroup In DescriptionOfParameterGroups Do
		
		Protocol.AddLine("	" + CurrentGroup.Description + ":");
		
		GroupParameters = ParametersDetails.FindRows(New Structure("Parent", CurrentGroup.Name)); // See CostCalculationAppliedAlgorithms.DescriptionOfParametersOfMonthClosingOperation
		
		For Each CurrentParameter In GroupParameters Do
			
			CurParameterValue = ParameterValues[CurrentParameter.Name];
			
			If CurParameterValue <> CurrentParameter.DefaultValue Then
				AdditionToDescription = "; (" + NStr("vi = 'giá trị mặc định';
													|ru = 'значение по умолчанию';
													|en = 'default value'; fa = 'default value';
													|it = 'valore predefinito';
													|pl = 'wartość domyślna';
													|tr = 'varsayılan değer'", Common.DefaultLanguageCode()) + ": "
					+ ValuePresentation(CurrentParameter.DefaultValue) + ")";
			Else
				AdditionToDescription = "";
			EndIf;
			
			Protocol.AddLine("		- " + CurrentParameter.Description + ": "
				+ ValuePresentation(CurParameterValue) + AdditionToDescription);
			
		EndDo;
		
	EndDo;
	
	// We will display information about the parameters of cost allocation and cost calculation.
	ParametersDetails 		= CostCalculationAppliedAlgorithms.DescriptionOfParametersOfMonthClosingOperation();
	DescriptionOfParameterGroups = CostCalculationAppliedAlgorithms.DescriptionOfGroupsOfParametersForMonthClosingOperation(); //ValueTable
	ParameterValues 		= CalculationOfCostCached.ValuesOfTechnologicalParameters();
	
	For Each CurrentGroup In DescriptionOfParameterGroups Do
		
		Protocol.AddLine("	" + CurrentGroup.Description + ":");
		
		GroupParameters = ParametersDetails.FindRows(New Structure("Parent", CurrentGroup.Name)); // See CostCalculationAppliedAlgorithms.DescriptionOfParametersOfMonthClosingOperation
		
		For Each CurrentParameter In GroupParameters Do
			
			CurParameterValue = ParameterValues[CurrentParameter.Name];
			
			If CurParameterValue <> CurrentParameter.DefaultValue Then
				AdditionToDescription = "; (" + NStr("vi = 'giá trị mặc định';
													|ru = 'значение по умолчанию';
													|en = 'default value'; fa = 'default value';
													|it = 'valore predefinito';
													|pl = 'wartość domyślna';
													|tr = 'varsayılan değer'", Common.DefaultLanguageCode()) + ": "
					+ ValuePresentation(CurrentParameter.DefaultValue) + ")";
			Else
				AdditionToDescription = "";
			EndIf;
			
			Protocol.AddLine("		- " + CurrentParameter.Description + ": "
				+ ValuePresentation(CurParameterValue) + AdditionToDescription);
			
		EndDo;
		
	EndDo;
	
	// We will output information about the registers being serviced.
	If CalculationParameters.Property("RegisterRecords") Then
		
		Protocol.AddLine("");
		Protocol.AddLine(ProtocolPartSeparator());
		Protocol.AddLine(NStr("vi = 'Biểu ghi hệ thống:';
								|ru = 'Обслуживаемые регистры:';
								|en = 'Maintained registers:'; fa = 'Maintained registers:';
								|it = 'Registri serviti:';
								|pl = 'Obsługiwane rejestry:';
								|tr = 'Hizmet eden kayıt defterleri:'", Common.DefaultLanguageCode()));
		
		For Each RegisterDescription In CalculationParameters.RegisterRecords Do
			Protocol.AddLine("	- " + RegisterDescription.Value.FullRegisterName
				+ ?(CalculationParameters.RegistersWithCalculatedRevolutions.Property(RegisterDescription.Key),
					" (" + NStr("vi = 'bộ đệm phát sinh';
								|ru = 'кэш оборотов';
								|en = 'turnover cache'; fa = 'turnover cache';
								|it = 'cache dei fatturati';
								|pl = 'pamięć podręczna obrotów';
								|tr = 'ciro önbellekleri'", Common.DefaultLanguageCode()) + ")", "")
				+ ?(CalculationParameters.RegistersWithCalculatedBalances.Property(RegisterDescription.Key),
					" (" + NStr("vi = 'bộ đệm dư';
								|ru = 'кэш остатков';
								|en = 'balance cache'; fa = 'balance cache';
								|it = 'cache delle rimanenze';
								|pl = 'pamięć podręczna pozostałości';
								|tr = 'bakiye önbelleği'", Common.DefaultLanguageCode()) + ")", ""));
		EndDo;
		
	EndIf;
	
#EndRegion

#Region CalculationStages
	
	Protocol.AddLine("");
	Protocol.AddLine(ProtocolPartSeparator());
	Protocol.AddLine(NStr("vi = 'Giao thức thực hiện các giai đoạn tính toán:';
							|ru = 'Протокол выполнения этапов расчета:';
							|en = 'Protocol of settlement step execution:'; fa = 'Protocol of settlement step execution:';
							|it = 'Protocollo di esecuzione delle fasi di calcolo:';
							|pl = 'Protokół wykonywania kroków obliczeniowych:';
							|tr = 'Hesaplama adımlarını tamamlamak için bir protokol:'", Common.DefaultLanguageCode()));
	
	Counter = 0;
	
	For Each StageDescription In CalculationProtocol.Stages Do
		
		Counter = Counter + 1;
		
		Protocol.AddLine("");
		Protocol.AddLine(TrimAll(Counter) + ". " + StageDescription.PresentationStage); // The level of this step is not supported yet
		Protocol.AddLine(NStr("vi = 'Bắt đầu công đoạn:';
								|ru = 'Начало этапа:';
								|en = 'Stage start:'; fa = 'Stage start:';
								|it = 'Inizio della fase:';
								|pl = 'Początek etapu:';
								|tr = 'Aşamanın başlangıcı:'", Common.DefaultLanguageCode()) + " " + ValuePresentation(StageDescription.StartDate)
			+ ", " + NStr("vi = 'thời lượng:';
							|ru = 'длительность:';
							|en = 'duration:'; fa = 'duration:';
							|it = 'durata:';
							|pl = 'duration:';
							|tr = 'süre:'", Common.DefaultLanguageCode()) + " " + RuntimePresentation(StageDescription, CalculationProtocol));
		Protocol.AddLine(NStr("vi = 'Thời gian bắt đầu tính toán đến khi bắt đầu giai đoạn:';
								|ru = 'Время от начала расчета до начала этапа:';
								|en = 'Time from calculation start to stage start:'; fa = 'Time from calculation start to stage start:';
								|it = 'Tempo dall''inizio del calcolo all''inizio della fase:';
								|pl = 'Czas od początku obliczenia do początku etapu:';
								|tr = 'Hesaplamanın başlangıcından aşamanın başlangıcına kadarki süre:'", Common.DefaultLanguageCode()) + " " + TimePresentation(StageDescription.StartDate - CalculationProtocol.StartDate));
		
		If ValueIsFilled(StageDescription.FormedRegisteredRecords) Then
			Protocol.AddLine(NStr("vi = 'Đã tạo bản ghi kết chuyển theo biểu ghi (tổng số / duy nhất):';
									|ru = 'Сформированы движения по регистрам (всего / уникальных):';
									|en = 'Records in registers are generated (total / unique):'; fa = 'Records in registers are generated (total / unique):';
									|it = 'Creati i movimenti sui registri (totali / unici):';
									|pl = 'Utworzone ruchy według rejestrów (ogółem/unikatowe):';
									|tr = 'Kayıt defterleri tarafından oluşturulan hareketler (toplam / benzersiz):'", Common.DefaultLanguageCode()));
			For Each RegisterRecordsDetails In StageDescription.FormedRegisteredRecords Do
				Protocol.AddLine("	- " + RegisterRecordsDetails.Key + ": "
					+ ValuePresentation(RegisterRecordsDetails.Value.Total) + " / "
					+ ValuePresentation(RegisterRecordsDetails.Value.Unique_));
			EndDo;
		EndIf;
		
		If ValueIsFilled(StageDescription.GeneratedTTStrings) Then
			Protocol.AddLine(NStr("vi = 'Đã tạo các dòng của bảng phụ tạm thời (tổng số / duy nhất):';
									|ru = 'Сформированы строки вспомогательных временных таблиц (всего / уникальных):';
									|en = 'Rows of auxiliary temporary tables are generated (total / unique):'; fa = 'Rows of auxiliary temporary tables are generated (total / unique):';
									|it = 'Create le righe delle tabelle ausiliarie temporanee (totali / uniche):';
									|pl = 'Utworzone wiersze pomocniczych tabel tymczasowych (ogółem/unikatowe):';
									|tr = 'Yardımcı geçici tablo satırları (toplam / benzersiz) oluşturuldu:'", Common.DefaultLanguageCode()));
			For Each RegisterRecordsDetails In StageDescription.GeneratedTTStrings Do
				Protocol.AddLine("	- " + RegisterRecordsDetails.Key + ": "
					+ ValuePresentation(RegisterRecordsDetails.Value.Total) + " / "
					+ ValuePresentation(RegisterRecordsDetails.Value.Unique_));
			EndDo;
		EndIf;
		
		If ValueIsFilled(StageDescription.TemporaryTable) Then
			
			Protocol.AddLine(NStr("vi = 'Đã tạo các bảng tạm (kích thước / thời gian (% thời gian trong công đoạn) / làm rõ / bảng nguồn):';
									|ru = 'Сформированы временные таблицы (размер / время (% времени этапа) / уточнение / исходные таблицы):';
									|en = 'Temporary tables are generated (size / time (% of step time) / clarification / original tables):'; fa = 'Temporary tables are generated (size / time (% of step time) / clarification / original tables):';
									|it = 'Create le tabelle temporanee (dimensione / tempo (% del tempo della fase) / affinamento / tabelle iniziali):';
									|pl = 'Utworzone tabele tymczasowe (rozmiar / czas (% czas etapu) / doprecyzowanie / źródła tabeli):';
									|tr = 'Oluşturulan geçici tablolar (boyut / zaman (aşama süresinin %''si) / iyileştirme / kaynak tabloları):'", Common.DefaultLanguageCode()));
			FormationTimeOfAllTables = New Structure("TotalTime", 0);
			
			For Each TableDetails In StageDescription.TemporaryTable Do
				
				Protocol.AddLine("	- " + TableDetails.Key + ": ");
				
				For Each ActionDetails In TableDetails.Value Do
					
					If ValueIsFilled(ActionDetails.BeginTime) And ValueIsFilled(ActionDetails.EndTime) Then
						FormationTimeOfAllTables.TotalTime = FormationTimeOfAllTables.TotalTime + (ActionDetails.EndTime - ActionDetails.BeginTime);
					EndIf;
					
					Protocol.AddLine("		- "
						+ ValuePresentation(ActionDetails.RowsCount)
						+ " / " + RuntimePresentation(ActionDetails, StageDescription)
						+ ?(Not ValueIsFilled(ActionDetails.Explanation), "",
							" / " + ValuePresentation(ActionDetails.Explanation))
						+ ?(Not ValueIsFilled(ActionDetails.RawData), "",
							" / " + ValuePresentation(ActionDetails.RawData)));
					
				EndDo;
				
			EndDo;
			
			If ValueIsFilled(FormationTimeOfAllTables.TotalTime) Then
				Protocol.AddLine(NStr("vi = 'Tổng thời gian lập bảng:';
										|ru = 'Общее время формирования таблиц:';
										|en = 'Total time of table generation:'; fa = 'Total time of table generation:';
										|it = 'Tempo totale di creazione delle tabelle:';
										|pl = 'Całkowity czas tworzenia tabel:';
										|tr = 'Tabloları oluşturmak için toplam süre:'", Common.DefaultLanguageCode()) + " "
					+ RuntimePresentation(FormationTimeOfAllTables, StageDescription));
			EndIf;
			
		EndIf;
		
		If ValueIsFilled(StageDescription.CodeExecutionMeasurements) Then
			
			Protocol.AddLine(NStr("vi = 'Đã thực hiện đo lường các đoạn mã (thời gian (% thời gian giai đoạn) / làm rõ):';
									|ru = 'Выполнены замеры фрагментов кода (время (% времени этапа) / уточнение):';
									|en = 'Measurements of code fragments are completed (time (% of the stage time) / specification):'; fa = 'Measurements of code fragments are completed (time (% of the stage time) / specification):';
									|it = 'Misurazioni dei frammenti del codice completate (tempo (% del tempo della fase) / affinamento):';
									|pl = 'Wykonano pomiary fragmentów kodu (czas (% czasu etapu) / sprecyzowanie):';
									|tr = 'Kod parçalarının ölçümleri (zaman (aşama süresinin %''si) / iyileştirme) gerçekleştirilmiştir:'", Common.DefaultLanguageCode()));
			TimeOfAllCodeMeasurements = New Structure("TotalTime", 0);
			
			For Each DescriptionOfCodeMeasurement In StageDescription.CodeExecutionMeasurements Do
				
				Protocol.AddLine("	- " + DescriptionOfCodeMeasurement.Key + ": ");
				
				For Each ActionDetails In DescriptionOfCodeMeasurement.Value Do
					
					TimeOfAllCodeMeasurements.TotalTime = TimeOfAllCodeMeasurements.TotalTime + (ActionDetails.EndTime - ActionDetails.BeginTime);
					
					Protocol.AddLine("		- "
						+ RuntimePresentation(ActionDetails, StageDescription)
						+ ?(Not ValueIsFilled(ActionDetails.Explanation), "",
							" / " + ValuePresentation(ActionDetails.Explanation)));
					
				EndDo;
				
			EndDo;
			
			Protocol.AddLine(NStr("vi = 'Tổng thời gian đo thực hiện mã:';
									|ru = 'Общее время замеров выполнения кода:';
									|en = 'Total time for measurements of code completion:'; fa = 'Total time for measurements of code completion:';
									|it = 'Tempo totale impiegato per le misurazioni del codice:';
									|pl = 'Całkowity czas pomiaru wykonywania kodu:';
									|tr = 'Kod gerçekleştirme ölçümlerinin toplam süresi:'", Common.DefaultLanguageCode()) + " "
				+ RuntimePresentation(TimeOfAllCodeMeasurements, StageDescription));
			
		EndIf;
		
		If ValueIsFilled(StageDescription.AdditionalInformation) Then
			
			Protocol.AddLine(" ");
			Protocol.AddLine(NStr("vi = 'Thông tin bổ sung về giai đoạn:';
									|ru = 'Дополнительная информация об этапе:';
									|en = 'Additional step information:'; fa = 'Additional step information:';
									|it = 'Informazione aggiuntiva sulla fase:';
									|pl = 'Dodatkowe informacje o etapie:';
									|tr = 'Aşama hakkında ek bilgi:'", Common.DefaultLanguageCode()));
			
			For Each DescriptionOfInformation In StageDescription.AdditionalInformation Do
				Protocol.AddLine(PresentationOfMultilineText(DescriptionOfInformation, "	- "));
			EndDo;
			
		EndIf;
		
		If ValueIsFilled(StageDescription.ErrorInformation_) Then
			DisplayErrorInformation(
				CalculationParameters,
				Protocol,
				StageDescription.ErrorInformation_,
				NStr("vi = 'Khi thực hiện giai đoạn tính toán, đã xảy ra lỗi';
					|ru = 'При выполнении этапа расчета обнаружены ошибки';
					|en = 'Errors are detected while performing the calculation step'; fa = 'Errors are detected while performing the calculation step';
					|it = 'Durante l''esecuzione della fase di calcolo sono stati rilevati degli errori';
					|pl = 'Podczas etapu obliczania zostały wykryte błędy';
					|tr = 'Hesaplama aşamasında hatalar bulundu'", Common.DefaultLanguageCode()),
				StageDescription.PresentationStage);
		EndIf;
		
	EndDo;
	
#EndRegion
	
#Region FinalIndicators
	
	// Duration of stages
	Protocol.AddLine("");
	Protocol.AddLine(ProtocolPartSeparator());
	Protocol.AddLine(NStr("vi = 'Thông tin tổng hợp về thời lượng các giai đoạn (tuyệt đối (tương đối)):';
							|ru = 'Итоговая информация о длительности этапов (абсолютная (относительная)):';
							|en = 'Summary stage duration (absolute (relative)):'; fa = 'Summary stage duration (absolute (relative)):';
							|it = 'Informazione di riepilogo sulla lunghezza delle fasi (assoluta (relativa)):';
							|pl = 'Podsumowanie informacji o czasie trwania etapów (bezwzględna (względna)):';
							|tr = 'Aşama uzunluğu ile ilgili toplam bilgi (mutlak (göreceli)):'", Common.DefaultLanguageCode()));
		
	TableOfDurationOfStages = New ValueTable;
	TableOfDurationOfStages.Columns.Add("Stage");
	TableOfDurationOfStages.Columns.Add("Duration");
	
	Counter = 0;
	
	For Each StageDescription In CalculationProtocol.Stages Do
		
		Counter = Counter + 1;
		
		Protocol.AddLine("	" + TrimAll(Counter) + ". " + StageDescription.PresentationStage + ": "
			+ RuntimePresentation(StageDescription, CalculationProtocol));
		
		NewRow = TableOfDurationOfStages.Add();
		NewRow.Stage = NStr("vi = 'Công đoạn';
							|ru = 'Этап';
							|en = 'Stage'; fa = 'مرحله';
							|it = 'Fase';
							|pl = 'Stage';
							|tr = 'Aşama'", Common.DefaultLanguageCode()) + " №" + TrimAll(Counter) + ". " + StageDescription.PresentationStage;
		NewRow.Duration = (StageDescription.EndTime - StageDescription.BeginTime + 1) / 1000;
		
	EndDo;
	
	TableOfDurationOfStages.Sort("Duration Desc");
	
	Protocol.AddLine("");
	Protocol.AddLine(NStr("vi = 'TOP 10 các giai đoạn dài nhất:';
							|ru = 'ТОП-10 самых длительных этапов:';
							|en = 'TOP 10 longest stages:'; fa = 'TOP 10 longest stages:';
							|it = 'TOP-10 delle fasi più lunghe:';
							|pl = 'TOP 10 najdłuższych etapów:';
							|tr = 'En uzun 10 aşama:'", Common.DefaultLanguageCode()));
	
	Counter = 0;
	
	While Counter < 10 And Counter < TableOfDurationOfStages.Count() Do
		
		Counter = Counter + 1;
		
		Protocol.AddLine("	" + TrimAll(Counter) + ". " + TableOfDurationOfStages[Counter - 1].Stage + ": "
			+ TimePresentation(TableOfDurationOfStages[Counter - 1].Duration));
		
	EndDo;
	
	// Formed by the movement of
	Protocol.AddLine("");
	Protocol.AddLine(ProtocolPartSeparator());
	Protocol.AddLine(NStr("vi = 'Thông tin tổng hợp về các bản ghi kết chuyển đã lập theo bản ghi (tổng số / riêng lẻ):';
							|ru = 'Итоговая информация о сформированных движениях по регистрам (всего / уникальных):';
							|en = 'Summary of generated records in registers (total / unique):'; fa = 'Summary of generated records in registers (total / unique):';
							|it = 'Informazione di riepilogo sui movimenti creati per i registri (totali / unici):';
							|pl = 'Podsumowanie informacji o wygenerowanych ruchach w rejestrach (ogółem/unikatowe):';
							|tr = 'Kayıtlar tarafından üretilen hareketlere ilişkin toplam bilgi (toplam / benzersiz):'", Common.DefaultLanguageCode()));
	
	If ValueIsFilled(CalculationProtocol.FormedRegisteredRecords) Then
		For Each RegisterRecordsDetails In CalculationProtocol.FormedRegisteredRecords Do
			
			Protocol.AddLine("	- " + RegisterRecordsDetails.Key + ": "
				+ ValuePresentation(RegisterRecordsDetails.Value.Total) + " / "
				+ ValuePresentation(RegisterRecordsDetails.Value.Unique_));
			
			If RegisterRecordsDetails.Value.Erroneous > 0 Then
				
				Protocol.AddLine("		- " + NStr("vi = 'trong đó lỗi:';
													|ru = 'в т.ч. ошибочных:';
													|en = 'including error:'; fa = 'including error:';
													|it = 'tra cui anche quelli errati:';
													|pl = 'w tym błędnych:';
													|tr = 'yanlış olanlar da dahil:'", Common.DefaultLanguageCode()) + " "
					+ ValuePresentation(RegisterRecordsDetails.Value.Erroneous) + " !");
				
				// We will output a description of the errors of the generated movements in the context of the recorders
				For Each ErrorDescription In RegisterRecordsDetails.Value.LoggerErrors Do
					
					Protocol.AddLine("		" + ValuePresentation(ErrorDescription.Key) + ":");
					
					For Each CurrentRegistrar In ErrorDescription.Value Do
						Protocol.AddLine("			- "	+ ValuePresentation(CurrentRegistrar)
							+ " (" + GetURL(CurrentRegistrar) + ")");
					EndDo;
					
				EndDo;
				
			EndIf;
			
		EndDo;
	Else
		Protocol.AddLine(NStr("vi = 'Không có bản ghi kết chuyển đã lập.';
								|ru = 'Нет сформированных движений.';
								|en = 'No generated movements.'; fa = 'No generated movements.';
								|it = 'Non ci sono movimenti creati.';
								|pl = 'Brak uformowanych ruchów.';
								|tr = 'Herhangi bir hareket olmadı.'", Common.DefaultLanguageCode()));
	EndIf;
	
	// We will output information about loggers' errors
	If ThereWereMovementErrors Then
		DisplayErrorInformation(
			CalculationParameters,
			Protocol,
			CalculationProtocol.MovementErrors,
			NStr("vi = 'Đã tạo bản ghi kết chuyển bị lỗi';
				|ru = 'Формирование движений выполнено с ошибками';
				|en = 'Movement generation is completed with errors'; fa = 'Movement generation is completed with errors';
				|it = 'La creazione dei movimenti è completata con errori';
				|pl = 'Tworzenie ruchów zakończone błędami';
				|tr = 'Hareketlerin oluşumu hatalarla gerçekleştirildi'", Common.DefaultLanguageCode()));
	EndIf;
	
	// Recorded movements
	Protocol.AddLine("");
	Protocol.AddLine(ProtocolPartSeparator());
	
	DocumentsCount 	= 0;
	RecordsCount		= 0;
	RecordingTime				= 0;
	
	If CalculationParameters.TotalNumberOfFederalLawEntries > 0 Then
		
		Protocol.AddLine(NStr("vi = 'Tổng số nhiệm vụ nền ghi lại bản ghi kết chuyển đã khởi động:';
								|ru = 'Всего запущено фоновых заданий записи движений:';
								|en = 'Total started background jobs for saving movements:'; fa = 'Total started background jobs for saving movements:';
								|it = 'Totale dei task di registrazione dei movimenti avviati in background:';
								|pl = 'Łączne zadania zapisu w tle z uruchomionym ruchem:';
								|tr = 'Başlatılan toplam hareket kaydı arka plan işi sayısı:'", Common.DefaultLanguageCode()) + " "
			+ ValuePresentation(CalculationParameters.TotalNumberOfFederalLawEntries));
		
		JobNumber = 0;
		
		For Each CurrentRow In CalculationParameters.RecordJobTable Do
			
			JobNumber = JobNumber + 1;
			
			Protocol.AddLine(
				TrimAll(JobNumber) + ". "
				+ CurrentRow.RegisterName + ": "
				+ CurrentRow.TextStatistics);
			
		EndDo;
		
	EndIf;
	
	Protocol.AddLine("");
	Protocol.AddLine(NStr("vi = 'Thông tin tổng hợp về các bản ghi kết chuyển đã ghi lại theo biểu ghi (chứng từ / bản ghi / thời gian ghi lại):';
							|ru = 'Итоговая информация о записанных движениях по регистрам (документов / записей / время записи):';
							|en = 'Summary of saved records in registers (documents / records / record time):'; fa = 'Summary of saved records in registers (documents / records / record time):';
							|it = 'Informazione di riepilogo sui movimenti sui registri registrati (documenti / registrazione / tempo di registrazione):';
							|pl = 'Podsumowanie informacji o zarejestrowanych ruchach w rejestrach (dokumentów/zapisów/czas zapisu):';
							|tr = 'Kayıtlara göre kaydedilen hareketlere ilişkin toplam bilgi (belgeler / kayıtlar / kayıt süresi):'", Common.DefaultLanguageCode())); // the number of records - taking into account the "primary"
	
	If ValueIsFilled(CalculationProtocol.FormedRegisteredRecords)
	 And CalculationProtocol.WritingRegisterRecords.Property("FormedRegisteredRecords") Then
		
		For Each RegisterRecordsDetails In CalculationProtocol.WritingRegisterRecords.FormedRegisteredRecords Do
			
			If RegisterRecordsDetails.Value.RecordsCount > 0 Or RegisterRecordsDetails.Value.DocumentsCount > 0 Then
				
				DocumentsCount = DocumentsCount + RegisterRecordsDetails.Value.DocumentsCount;
				RecordsCount    = RecordsCount + RegisterRecordsDetails.Value.RecordsCount;
				RecordingTime			 = RecordingTime + RegisterRecordsDetails.Value.RecordingTime;
				
				Protocol.AddLine("	- " + RegisterRecordsDetails.Key + ": "
					+ ValuePresentation(RegisterRecordsDetails.Value.DocumentsCount) + " / "
					+ ValuePresentation(RegisterRecordsDetails.Value.RecordsCount) + " / "
					+ TimePresentation(RegisterRecordsDetails.Value.RecordingTime));
				
				EndIf;
				
		EndDo;
		
	EndIf;
		
	If Not ThereWereRecordingErrors Then
		
		If RecordsCount > 0 Or DocumentsCount > 0 Then
			Protocol.AddLine(NStr("vi = 'Tổng số bản ghi kết chuyển theo biểu ghi đã được ghi lại:';
									|ru = 'Всего записано движений по регистрам:';
									|en = 'Total records saved for registers:'; fa = 'Total records saved for registers:';
									|it = 'Totale dei movimenti sui registri registrati:';
									|pl = 'Całkowite zarejestrowane ruchy w rejestrach:';
									|tr = 'Kayıt defterlerine göre kaydedilen toplam hareketler:'", Common.DefaultLanguageCode()) + " "
				+ ValuePresentation(DocumentsCount) + " / "
				+ ValuePresentation(RecordsCount) + " / "
				+ TimePresentation(RecordingTime));
		ElsIf RecordsCount = 0 And DocumentsCount = 0 Then
			Protocol.AddLine(NStr("vi = 'Chưa thực hiện ghi lại bản ghi kết chuyển - không có các bản ghi kết chuyển đã thay đổi.';
									|ru = 'Запись движений не выполнялась - нет измененных движений.';
									|en = 'Records have not been saved - no changed records.'; fa = 'Records have not been saved - no changed records.';
									|it = 'La registrazione dei movimenti non è stata effettuata - non ci sono movimenti modificati.';
									|pl = 'Nagrywanie ruchu nie zostało wykonane - brak zmienionych ruchów.';
									|tr = 'Hareketler kaydedilmedi - değiştirilmiş hareket yoktur.'", Common.DefaultLanguageCode()));
		EndIf;
		
	Else
		
		Protocol.AddLine("");
		
		DisplayErrorInformation(
			CalculationParameters,
			Protocol,
			CalculationProtocol.RecordingErrors,
			NStr("vi = 'Đã thực hiện bản ghi kết chuyển bị lỗi';
				|ru = 'Запись движений выполнена с ошибками';
				|en = 'Errors occurred when saving records'; fa = 'Errors occurred when saving records';
				|it = 'La registrazione dei movimenti è completata con errori';
				|pl = 'Nagrywanie ruchu zakończone z błędami';
				|tr = 'Hareketlerin kaydı hatalarla gerçekleştirildi'", Common.DefaultLanguageCode()));
		
	EndIf;
	
	If ValueIsFilled(CalculationProtocol.WritingRegisterRecords) Then
		Protocol.AddLine("");
		Protocol.AddLine(NStr("vi = 'Thời lượng giao dịch ghi lại:';
								|ru = 'Длительность операций записи:';
								|en = 'Duration of saving operations:'; fa = 'Duration of saving operations:';
								|it = 'Durata delle operazioni di registrazione:';
								|pl = 'Czas trwania operacji zapisu:';
								|tr = 'Kayıt işlemlerinin uzunluğu:'", Common.DefaultLanguageCode()) + " "
			+ RuntimePresentation(CalculationProtocol.WritingRegisterRecords, CalculationProtocol));
	EndIf;
	
	If CalculationParameters.Property("LogOfRegisterRecords") And ValueIsFilled(CalculationParameters.LogOfRegisterRecords) Then
		Protocol.AddLine("");
		Protocol.AddLine(NStr("vi = 'Nhật ký hoạt động của cơ chế ghi bản ghi kết chuyển:';
								|ru = 'Лог работы механизма записи движений:';
								|en = 'Log of record saving tool:'; fa = 'Log of record saving tool:';
								|it = 'Лог работы механизма записи движений:';
								|pl = 'Log of record saving tool:';
								|tr = 'Hareket kaydı mekanizması işlem kaydı kayıtları:'", Common.DefaultLanguageCode()));
		Protocol.AddLine(TrimAll(CalculationParameters.LogOfRegisterRecords));
	EndIf;
	
	Protocol.AddLine("");
	Protocol.AddLine(ProtocolPartSeparator());
	
#EndRegion

#Region SavingCalculationProtocol

	ProtocolText = Protocol.GetText();
	
	ProtocolText = StrReplace(ProtocolText, TrimAll(CostCalculationAppliedAlgorithms.ServiceSymbol_TextToLogProblem()), "");
	ProtocolText = StrReplace(ProtocolText, TrimAll(CostCalculationAppliedAlgorithms.ServiceSymbol_ProblemAlreadyRegistered()), "");
	
	Protocol.SetText(ProtocolText);
	
	// Let's write the protocol in the log
	If CalculationProtocol.CalculationIsCompleted Then
		WriteLogEvent(
			CostCalculationAppliedAlgorithms.EventNameProtocolForLog(CalculationParameters),
			EventLogLevel.Information,
			,
			,
			ProtocolText);
	EndIf;
	
	// Let's delete the previous intermediate calculation protocol.
	RecordSet = InformationRegisters.LotAndCostCalculationProtocols.CreateRecordSet();
	RecordSet.Filter.Id.Set(CalculationProtocol.Id);
	RecordSet.Write(True);
	
	// Let's write the protocol in the data register
	RecordingProtocol = InformationRegisters.LotAndCostCalculationProtocols.CreateRecordManager();
	
	RecordingProtocol.Period 					 = CurrentSessionDate();
	RecordingProtocol.Id 			 = CalculationProtocol.Id;
	
	RecordingProtocol.Protocol 				 = New ValueStorage(Protocol, New Deflation(9));
	
	RecordingProtocol.CalculationDuration 	 = CalculationProtocol.Duration;
	RecordingProtocol.CalculationOption 			 = CalculationParameters.CalculationOption;
	RecordingProtocol.MonthEndClosingMode		 = CalculationParameters.MonthEndClosingMode;
	RecordingProtocol.CalculationPeriod 			 = CalculationParameters.PayrollPeriod.BeginOfPeriod;
	RecordingProtocol.HadErrors 				 = Not CalculationProtocol.CalculationIsCompleted Or HadErrors;
	RecordingProtocol.ErrorsDescription 			 = ?(CalculationProtocol.CalculationIsCompleted, PresentationOfCalculationErrors(CalculationProtocol), NStr("vi = 'Chưa hoàn thành tính toán';
																																								|ru = 'Расчет не завершен';
																																								|en = 'Calculation is not completed'; fa = 'محاسبه تکمیل نشده است';
																																								|it = 'Calcolo non è stato terminato';
																																								|pl = 'Obliczenia nie zostały zakończone';
																																								|tr = 'Hesaplama tamamlanmadı'", Common.DefaultLanguageCode()));
	RecordingProtocol.CalculatedCompanies =
		CostCalculationAppliedAlgorithms.CalculatedCompanies(OrganizationsForProtocol, ", ", True);
	RecordingProtocol.CalculationIsNotCompleted		 = Not CalculationProtocol.CalculationIsCompleted;
	
	
	RecordingProtocol.CalculatedCompanies =
		CostCalculationAppliedAlgorithms.CalculatedCompanies(CalculationParameters.CompanyArray, ", ", True);
	
	RecordingProtocol.Write(True);
	
#EndRegion

EndProcedure

	
// Determines whether the Protocol was initialized.
//
// Returns:
//	Boolean - 
//
Function CalculationProtocolIsMaintained(CalculationParameters) Export
	
	Return TypeOf(CalculationParameters) = Type("Structure") And CalculationParameters.Property("CalculationProtocol");
	
EndFunction

// Returns the Protocol ID in the Protocol information register of the Partyaccountpartyssubstantiation.
//
// Returns:
//	UUID -
//
Function UniqueProtocolID(CalculationParameters) Export
	CalculationProtocol = CalculationParameters.CalculationProtocol; // See CostCalculationProtocol.InitializeCalculationProtocol 
	Return CalculationProtocol.Id;
EndFunction

#EndRegion

#Region LoggingOfCalculationSteps

// Logs the start of the calculation stage.
//
Procedure StartOfCalculationStage(CalculationParameters, PresentationStage, StageLevel = 1) Export
	
	If Not ValueIsFilled(CalculationParameters) Then
		Return; // calculation parameters have not been initialized yet
	EndIf;
	
	CalculationParameters.Insert("PresentationStage", PresentationStage);
	
	If Not CalculationProtocolIsMaintained(CalculationParameters) Then
		CalculationStart(CalculationParameters);
	Else
		CostCalculationAppliedAlgorithms.RunNextWriteJobFromStack(CalculationParameters);
	EndIf;
	
	CalculationProtocol = CalculationParameters.CalculationProtocol; // See CostCalculationProtocol.InitializeCalculationProtocol 
	
	// If there was no explicit announcement of the end of the previous stage of the calculation, then we will close it due to the beginning of a new stage.
	EndOfCalculationStage(CalculationParameters);
	
	If CalculationParameters.Property("Performance") Then
		CalculationParameters.Performance.StageName = PresentationStage;
	EndIf;
	
	FullStagePresentation =
		?(CalculationParameters.PartiesAreBeingCalculated, NStr("vi = 'Kế toán theo lô';
																|ru = 'Партионный учет';
																|en = 'Lot accounting'; fa = 'حسابداری لات';
																|it = 'Contabilità per lotti';
																|pl = 'Ewidencja partii';
																|tr = 'Lot muhasebesi'", Common.DefaultLanguageCode()), NStr("vi = 'Tính giá vốn';
																															|ru = 'Расчет себестоимости';
																															|en = 'Cost calculation'; fa = 'محاسبه بهای تمام‌شده';
																															|it = 'Calcolo del costo di produzione';
																															|pl = 'Kalkulacja wartości własnej';
																															|tr = 'Maliyet hesaplaması'", Common.DefaultLanguageCode()))
		+ ": " + PresentationStage;
	
	If StageLevel = 1 Then
		// Let's make a record of the beginning of the stage in the LR
		MarkInLog(CalculationParameters, FullStagePresentation);
	EndIf;
	
	StageDescription = CalculationProtocol.Stages.Add();
	
	StageDescription.PresentationStage 	 	= FullStagePresentation;
	StageDescription.StageLevel 			 	= StageLevel;
	StageDescription.StartDate 	 		 	= CurrentSessionDate();
	StageDescription.BeginTime 	 		 	= CurrentUniversalDateInMilliseconds();
	StageDescription.FormedRegisteredRecords 	= New Structure;
	StageDescription.GeneratedTTStrings 	= New Structure;
	StageDescription.TemporaryTable 		 	= New Structure;
	StageDescription.CodeExecutionMeasurements	 	= New Structure;
	StageDescription.ErrorInformation_ 		= New Map;
	StageDescription.DataVolume			= 0;
	StageDescription.AdditionalInformation 	= New Array;
	
EndProcedure

// Logs the end of the calculation stage.
// You don't need to call it explicitly - it is called at the beginning of the next stage.
//
Procedure EndOfCalculationStage(CalculationParameters, CalculationEnd = False) Export
	
	CalculationProtocol = CalculationParameters.CalculationProtocol; // See CostCalculationProtocol.InitializeCalculationProtocol 
	StageDescription 	= CurStageDescription(CalculationParameters);
	
	If Not ValueIsFilled(StageDescription) // haven't started logging the calculation yet
	 Or ValueIsFilled(StageDescription.EndTime) Then // the protocol of the stage has already been formed
		Return;
	EndIf;
	
	StageDescription.EndTime = CurrentUniversalDateInMilliseconds();
	
	For Each RegisterRecordDetails In StageDescription.FormedRegisteredRecords Do
		
		If Not CalculationProtocol.FormedRegisteredRecords.Property(RegisterRecordDetails.Key) Then
			CleaningUpFormedRegisteredRecords(CalculationParameters, RegisterRecordDetails.Key); // initializes motion counters
		EndIf;
		
		// Let's count the number of unique movements formed at the current stage
		TotalRegisteredRecords = CostCalculationAppliedAlgorithms.TemporaryTableSize(CalculationParameters, CalculationParameters.RegisterRecords[RegisterRecordDetails.Key].RegisterCacheTableName);
		StageDescription.FormedRegisteredRecords[RegisterRecordDetails.Key].Unique_ =
			TotalRegisteredRecords - CalculationProtocol.FormedRegisteredRecords[RegisterRecordDetails.Key].Unique_;
		
		// Recalculate the total number of generated movements
		CalculationProtocol.FormedRegisteredRecords[RegisterRecordDetails.Key].Total = 
			CalculationProtocol.FormedRegisteredRecords[RegisterRecordDetails.Key].Total + RegisterRecordDetails.Value.Total;
		CalculationProtocol.FormedRegisteredRecords[RegisterRecordDetails.Key].Unique_ = TotalRegisteredRecords;
		
	EndDo;
	
	For Each RegisterRecordDetails In StageDescription.GeneratedTTStrings Do
		
		// Let's count the number of unique movements formed at the current stage
		TotalRegisteredRecords = CostCalculationAppliedAlgorithms.TemporaryTableSize(CalculationParameters, RegisterRecordDetails.Key);
		StageDescription.GeneratedTTStrings[RegisterRecordDetails.Key].Unique_ = TotalRegisteredRecords;
		
	EndDo;
	
	// Let's fix the performance measurement data.
	RecordTimeMeasurement(CalculationParameters);
	
	If Not CalculationEnd And CalculationOfCostCached.ValuesOfTechnologicalParameters().GenerateIntermediateCalculationProtocols Then
		GeneratePaymentProtocol(CalculationParameters);
	EndIf;
	
	If CalculationParameters.DebugParameters.Property("NameOfMotionSearchRegister")
	 And CalculationParameters.DebugParameters.Property("MotionSearchCondition") Then
		CostCalculationAppliedAlgorithms.CheckConditionForSearchingForRegisteredRecordsWhenCalculating(CalculationParameters);
	EndIf;
		
EndProcedure

// Returns a description of the current stage.
//
Function CurStageDescription(CalculationParameters)
	
	CalculationProtocol = CalculationParameters.CalculationProtocol; // See CostCalculationProtocol.InitializeCalculationProtocol 
	
	If CalculationProtocol.Stages.Count() = 0 Then
		CurStageDescription = Undefined;
	Else
		CurStageDescription = CalculationProtocol.Stages.Get(CalculationProtocol.Stages.Count()-1);
	EndIf;
	
	Return CurStageDescription;
	
EndFunction

// Returns a text description of the current stage.
//
// Returns:
//	String - 
//
Function PresentationOfCurStage(CalculationParameters) Export
	
	LongDesc = CurStageDescription(CalculationParameters);
	
	If Not ValueIsFilled(LongDesc) Then
		Return "";
	EndIf;
	
	Return LongDesc.PresentationStage;
	
EndFunction

#EndRegion

#Region LoggingTemporaryTables

// Logs the beginning of forming a temporary table (inside the calculation stage).
//
Procedure StartCreatingTemporaryTable(CalculationParameters, TempTableName, Explanation = "", SourceTableNames = "", BeginTime = Undefined) Export
	
	If Not CalculationProtocolIsMaintained(CalculationParameters) Then
		Return;
	EndIf;
	
	CalculationProtocol = CalculationParameters.CalculationProtocol; // See CostCalculationProtocol.InitializeCalculationProtocol 
	
	MeasurementDetails = New Structure;
	MeasurementDetails.Insert("TempTableName", TempTableName);
	MeasurementDetails.Insert("BeginTime", 		   ?(ValueIsFilled(BeginTime), BeginTime, CurrentUniversalDateInMilliseconds()));
	MeasurementDetails.Insert("Explanation", 		   Explanation);
	MeasurementDetails.Insert("RawData", 	   "");
	
	If ValueIsFilled(SourceTableNames) Then
		
		TextSourceData = "";
		
		For Each KeyAndValue In New Structure(SourceTableNames) Do
			TextSourceData =
				TextSourceData + ?(TextSourceData = "", "", ", ")
				+ KeyAndValue.Key + " ("
				+ ValuePresentation(
					CostCalculationAppliedAlgorithms.TemporaryTableSize(CalculationParameters, KeyAndValue.Key)) + ")";
		EndDo;
		
		MeasurementDetails.RawData = TextSourceData;
		
	EndIf;
	
	If Not CalculationProtocol.Property("CreatingTemporaryTable") Then
		CalculationProtocol.Insert("CreatingTemporaryTable", New Array);
	EndIf;
	
	CalculationProtocol.CreatingTemporaryTable.Add(MeasurementDetails);
	
EndProcedure

// Logs the end of forming a temporary table (inside the calculation stage).
//
Procedure EndFormationOfTemporaryTable(CalculationParameters, IncrementPerformanceMeasurementCounter = False, DataVolume = Undefined, EndTime = Undefined) Export
	
	If Not CalculationProtocolIsMaintained(CalculationParameters) Then
		Return;
	EndIf;
	
	CalculationProtocol 	= CalculationParameters.CalculationProtocol; // See CostCalculationProtocol.InitializeCalculationProtocol 
	StageDescription 		= CurStageDescription(CalculationParameters);
	MeasurementDetails		= CalculationProtocol.CreatingTemporaryTable[CalculationProtocol.CreatingTemporaryTable.Count() - 1];
	
	If Not StageDescription.TemporaryTable.Property(MeasurementDetails.TempTableName) Then
		CurTemporaryTable = New Array;
	Else
		CurTemporaryTable = StageDescription.TemporaryTable[MeasurementDetails.TempTableName]; // Array
	EndIf;
	
	If DataVolume <> Undefined Then
		RowsCount = DataVolume;
	ElsIf CostCalculationAppliedAlgorithms.TemporaryTableExists(CalculationParameters, MeasurementDetails.TempTableName) Then
		RowsCount = CostCalculationAppliedAlgorithms.TemporaryTableSize(CalculationParameters, MeasurementDetails.TempTableName);
		DataVolume = RowsCount;
	Else
		RowsCount = 0;
	EndIf;
	
	DescriptionOfTheTemporaryTable = New Structure;
	DescriptionOfTheTemporaryTable.Insert("RowsCount", RowsCount);
	DescriptionOfTheTemporaryTable.Insert("BeginTime", 	 MeasurementDetails.BeginTime);
	DescriptionOfTheTemporaryTable.Insert("EndTime",  ?(ValueIsFilled(EndTime), EndTime, CurrentUniversalDateInMilliseconds()));
	DescriptionOfTheTemporaryTable.Insert("Explanation", 		 MeasurementDetails.Explanation);
	DescriptionOfTheTemporaryTable.Insert("RawData",  MeasurementDetails.RawData);
	
	CurTemporaryTable.Add(DescriptionOfTheTemporaryTable);
	StageDescription.TemporaryTable.Insert(MeasurementDetails.TempTableName, CurTemporaryTable);
	
	CalculationProtocol.CreatingTemporaryTable.Delete(CalculationProtocol.CreatingTemporaryTable.Count() - 1);
	
	If IncrementPerformanceMeasurementCounter Then
		IncreaseAmountOfProcessedDataForMeasurement(CalculationParameters, RowsCount);
	EndIf;
	
EndProcedure

#EndRegion

#Region LoggingCodeSnippets


// Initializes the structure of the measurement description for a code fragment.
// 
// Returns:
// 	Structure - LongDesc:
// * Explanation - String -
// * Id - String -
// * BeginTime - Number -
//
Function InitializeDescriptionOfCodeFragmentExecution() Export
	
	MeasurementDetails = New Structure;
	MeasurementDetails.Insert("BeginTime", 		0);
	MeasurementDetails.Insert("Id",    "");
	MeasurementDetails.Insert("Explanation", 		"");
	
	Return MeasurementDetails;
	
EndFunction
	
// Logs the start of code snippet execution (inside the calculation stage).
// Nesting of code snippet measurements is not allowed.
//
Procedure StartOfCodeSnippetExecution(CalculationParameters, Id, Explanation) Export
	
	If Not CalculationProtocolIsMaintained(CalculationParameters) Then
		Return;
	EndIf;
	
	CalculationProtocol = CalculationParameters.CalculationProtocol; // See CostCalculationProtocol.InitializeCalculationProtocol 
	
	MeasurementDetails = InitializeDescriptionOfCodeFragmentExecution();
	MeasurementDetails.BeginTime = CurrentUniversalDateInMilliseconds();
	MeasurementDetails.Id = Id;
	MeasurementDetails.Explanation = Explanation;
	
	If Not CalculationProtocol.Property("ExecutingCodeSnippet") Then
		CalculationProtocol.Insert("ExecutingCodeSnippet", New Array);
	EndIf;
	
	CalculationProtocol.ExecutingCodeSnippet.Add(MeasurementDetails);
	
EndProcedure

// Logs the end of the code fragment execution (inside the calculation stage).
//
Procedure EndOfCodeSnippetExecution(CalculationParameters, AmountOfDataToMeasurePerformance = 0) Export
	
	If Not CalculationProtocolIsMaintained(CalculationParameters) Then
		Return;
	EndIf;
	
	CalculationProtocol 	= CalculationParameters.CalculationProtocol; // See CostCalculationProtocol.InitializeCalculationProtocol 
	StageDescription 		= CurStageDescription(CalculationParameters);
	MeasurementDetails 		= CostCalculationProtocol.InitializeDescriptionOfCodeFragmentExecution();
	FillPropertyValues(MeasurementDetails, CalculationProtocol.ExecutingCodeSnippet.Get(CalculationProtocol.ExecutingCodeSnippet.Count() - 1));
	CodeExecutionMeasurements = StageDescription.CodeExecutionMeasurements;
	
	If Not CodeExecutionMeasurements.Property(MeasurementDetails.Id) Then
		CurFroze = New Array; 
	Else
		CurFroze = CodeExecutionMeasurements[MeasurementDetails.Id]; // Array 
	EndIf;
	
	MeasurementDetails.Insert("DataVolume", AmountOfDataToMeasurePerformance);
	MeasurementDetails.Insert("EndTime",   CurrentUniversalDateInMilliseconds());
	
	CurFroze.Add(MeasurementDetails);
	CodeExecutionMeasurements.Insert(MeasurementDetails.Id, CurFroze);
	
	CalculationProtocol.ExecutingCodeSnippet.Delete(CalculationProtocol.ExecutingCodeSnippet.Count() - 1);
	
	If AmountOfDataToMeasurePerformance > 0 Then
		IncreaseAmountOfProcessedDataForMeasurement(CalculationParameters, AmountOfDataToMeasurePerformance);
	EndIf;
	
EndProcedure

#EndRegion

#Region LoggingRegisteredRecords

// Logs the beginning of recording formed movements.
//
Procedure StartRecordingRegisteredRecords(CalculationParameters, WriteRegisters) Export
	
	CalculationProtocol = CalculationParameters.CalculationProtocol; // See CostCalculationProtocol.InitializeCalculationProtocol 
	WritingRegisterRecords	= CalculationProtocol.WritingRegisterRecords;
	
	// If there was no explicit announcement of the end of the previous stage of the calculation, then we will close it due to the beginning of a new stage.
	EndOfCalculationStage(CalculationParameters);
	
	If CalculationParameters.Debug.KeepLogOfRegisterRecordsMechanism
	 And Not CalculationParameters.Property("LogOfRegisterRecords") Then
		CalculationParameters.Insert("LogOfRegisterRecords", "");
	EndIf;
	
	If ValueIsFilled(WriteRegisters) Then
		CalculationProtocol.NumberOfRegisteredRecordedCalls = CalculationProtocol.NumberOfRegisteredRecordedCalls + 1;
		StageNameSuffix = "ReadyMadeRegisteredRecorded" + Format(CalculationProtocol.NumberOfRegisteredRecordedCalls, "NG=");
	Else
		If CalculationProtocol.NumberOfRegisteredRecordedCalls = 0 Then
			StageNameSuffix = ""; // the record is called only 1 time for the entire calculation
		Else
			StageNameSuffix = "RemainingRegisteredRecords"; // the last call to record Registered Recorded movements
		EndIf;
	EndIf;
		
	StartOfCalculationStage(CalculationParameters, "RecordGeneratedRegisteredRecords" + ?(StageNameSuffix = "", "", "_") + StageNameSuffix);
	
	WritingRegisterRecords.Insert("BeginTime", CurrentUniversalDateInMilliseconds());
	
	If Not WritingRegisterRecords.Property("FormedRegisteredRecords") Then
		WritingRegisterRecords.Insert("FormedRegisteredRecords", New Structure);
	EndIf;
	
EndProcedure

// Logs the end of the recording of the generated movements.
//
Procedure EndOfMotionRecording(CalculationParameters) Export
	
	WritingRegisterRecords = CalculationParameters.CalculationProtocol.WritingRegisterRecords;
	
	WritingRegisterRecords.Insert("EndTime", CurrentUniversalDateInMilliseconds());
	
	TotalTime = ?(WritingRegisterRecords.Property("TotalTime"), WritingRegisterRecords.TotalTime, 0);
	WritingRegisterRecords.Insert("TotalTime", TotalTime + (WritingRegisterRecords.EndTime - WritingRegisterRecords.BeginTime));
	
EndProcedure

// Adds entries to the log of the movement recording mechanism.
//
Procedure AddRegisteredRecordedInformation(CalculationParameters, ProtocolText_) Export
	
	If CalculationParameters.Property("LogOfRegisterRecords") Then
		CalculationParameters.LogOfRegisterRecords = CalculationParameters.LogOfRegisterRecords + Chars.LF
			+ Format(CurrentSessionDate(), "DLF=DT") + " " + ProtocolText_;
	EndIf;
	
EndProcedure

// Logs quantitative indicators of caching generated movements.
//
Procedure CachingGeneratedRegisteredRecords(CalculationParameters, RegisterName, NumberOfRowsInValueTable) Export
	
	StageDescription = CurStageDescription(CalculationParameters);
	
	If Not StageDescription.FormedRegisteredRecords.Property(RegisterName) Then
		StageDescription.FormedRegisteredRecords.Insert(
			RegisterName,
			New Structure("Total, Unique_", NumberOfRowsInValueTable, 0)); //in the table of values and in the temporary table (collapsed records)
	Else
		StageDescription.FormedRegisteredRecords[RegisterName].Total =
			StageDescription.FormedRegisteredRecords[RegisterName].Total + NumberOfRowsInValueTable;
	EndIf;
	
EndProcedure

// Logs quantitative indicators of caching of generated records in auxiliary temporary tables.
//
Procedure TTCachingOfGeneratedRecords(CalculationParameters, TableName, NumberOfRowsInValueTable) Export
	
	StageDescription = CurStageDescription(CalculationParameters);
	
	If Not StageDescription.GeneratedTTStrings.Property(TableName) Then
		StageDescription.GeneratedTTStrings.Insert(
			TableName,
			New Structure("Total, Unique_", NumberOfRowsInValueTable, 0)); //in the table of values and in the temporary table (collapsed records)
	Else
		StageDescription.GeneratedTTStrings[TableName].Total =
			StageDescription.GeneratedTTStrings[TableName].Total + NumberOfRowsInValueTable;
	EndIf;
	
EndProcedure

// Logs quantitative indicators for recording formed movements.
//
Procedure RecordingGeneratedRegisteredRecords(CalculationParameters, RegisterName, DocumentsCount = 0, RecordsCount = 0, RecordingTime = 0) Export
	
	If DocumentsCount = 0 And RecordsCount = 0 And RecordingTime = 0 Then
		Return;
	EndIf;
	
	WritingRegisterRecords	= CalculationParameters.CalculationProtocol.WritingRegisterRecords;
	
	If Not WritingRegisterRecords.FormedRegisteredRecords.Property(RegisterName) Then
		WritingRegisterRecords.FormedRegisteredRecords.Insert(
			RegisterName,
			New Structure("DocumentsCount, RecordsCount, RecordingTime", DocumentsCount, RecordsCount, RecordingTime));
	Else
		WritingRegisterRecords.FormedRegisteredRecords[RegisterName].DocumentsCount =
			WritingRegisterRecords.FormedRegisteredRecords[RegisterName].DocumentsCount + DocumentsCount;
		WritingRegisterRecords.FormedRegisteredRecords[RegisterName].RecordsCount =
			WritingRegisterRecords.FormedRegisteredRecords[RegisterName].RecordsCount + RecordsCount;
		WritingRegisterRecords.FormedRegisteredRecords[RegisterName].RecordingTime =
			WritingRegisterRecords.FormedRegisteredRecords[RegisterName].RecordingTime + RecordingTime;
	EndIf;
	
EndProcedure

// Registers the presence of errors in the generated movements in the calculation Protocol.
//
Procedure FixErrorsInGeneratedRegisteredRecords(CalculationParameters, RegisterDescription, TableName, ErrorDescription) Export
	
	If CostCalculationAppliedAlgorithms.TemporaryTableSize(CalculationParameters, TableName) = 0 Then
		Return;
	EndIf;
	
	QueryResult = CostCalculationAppliedAlgorithms.SelectLoggersTimePoints(CalculationParameters, TableName);
	
	If QueryResult.IsEmpty() Then
		Return; // there are no incorrect movements
	EndIf;
	
	CalculationProtocol = CalculationParameters.CalculationProtocol; // See CostCalculationProtocol.InitializeCalculationProtocol 
	If Not CalculationProtocol.FormedRegisteredRecords.Property(RegisterDescription.RegisterName) Then
		Return; // there are no calculated movements
	EndIf;
	
	RegisterRecordsDetails = CalculationProtocol.FormedRegisteredRecords[RegisterDescription.RegisterName];
	
	TableLoggers = QueryResult.Unload();
	
	Recorders = TableLoggers.Copy(, "Recorder");
	Recorders.GroupBy("Recorder", "");
	Recorders = Recorders.UnloadColumn("Recorder");
	
	RegisterRecordsDetails.LoggerErrors.Insert(ErrorDescription, Recorders);
	RegisterRecordsDetails.Erroneous = RegisterRecordsDetails.Erroneous + Recorders.Count();
	
	FixCalculationError(
		CalculationParameters,
		Enums.TypesOfLotAccountingAndCostErrors.AnErrorOccurredWhenGeneratingRecordsInRegisters);
		
	For Each CurrRow In TableLoggers Do
		
		CostCalculationAppliedAlgorithms.RegisterCalculationExecutionProblem(
			CalculationParameters,
			CurrRow.Organization,
			NStr("vi = 'Khi tạo các bản ghi kết chuyển, đã chẩn đoán được lỗi';
				|ru = 'При формировании движений диагностированы ошибки';
				|en = 'Errors were found when generating the movements'; fa = 'Errors were found when generating the movements';
				|it = 'Durante la creazione dei movimenti sono stati diagnosticati degli errori';
				|pl = 'Podczas tworzenia ruchów zdiagnozowano błędy';
				|tr = 'Hareketlerin oluşumunda hatalar tespit edilmiştir'", Common.DefaultLanguageCode()),
			ErrorDescription + ": " + TrimAll(CurrRow.Recorder),
			CurrRow.Recorder);
		
	EndDo;
	
EndProcedure

// Clears counters generated when the register cache is cleared and movements are generated again.
//
Procedure CleaningUpFormedRegisteredRecords(CalculationParameters, RegisterName) Export
	
	CalculationProtocol = CalculationParameters.CalculationProtocol; // See CostCalculationProtocol.InitializeCalculationProtocol 
	
	RegisterRecordsDetails = New Structure;
	RegisterRecordsDetails.Insert("Total", 				 0);
	RegisterRecordsDetails.Insert("Unique_", 		 0);
	RegisterRecordsDetails.Insert("Erroneous", 			 0);
	RegisterRecordsDetails.Insert("LoggerErrors", New Map);
	
	CalculationProtocol.FormedRegisteredRecords.Insert(RegisterName, RegisterRecordsDetails);
	
EndProcedure

#EndRegion

#Region LoggingAdditionalInformation

// Adds any text to the Protocol (inside the calculation stage).
//
Procedure AdditionalInformation(CalculationParameters, DescriptionText, TextForLog_ = Undefined) Export
	
	StageDescription	= CurStageDescription(CalculationParameters);
	
	StageDescription.AdditionalInformation.Add(DescriptionText);
	
	// We will record additional calculation information in the registration log.
	If ValueIsFilled(TextForLog_) Then
		
		WriteLogEvent(
			CostCalculationAppliedAlgorithms.EventNameAndLogInformation(CalculationParameters),
			EventLogLevel.Information,
			,
			,
			TextForLog_);
		
	EndIf;		
	
EndProcedure

#EndRegion

#Region LoggingCalculationErrors

// Adds information about the calculation error to the Protocol.
//
Procedure FixCalculationError(CalculationParameters, ErrorType,
			ProtocolText_ = Undefined, TextForLog_ = Undefined,
			CompanyArray = Undefined) Export
	
	If CalculationProtocolIsMaintained(CalculationParameters) Then
		
		If CalculationParameters.Property("DoNotFixCalculationError") Then
			CalculationParameters.Delete("DoNotFixCalculationError");
			Return;
		EndIf;
		
		CalculationProtocol = CalculationParameters.CalculationProtocol; // See CostCalculationProtocol.InitializeCalculationProtocol 
		
		FormattedTextForProtocol = ErrorTextPresentation(ProtocolText_);
		
		ErrorsCount = CalculationProtocol.CalculationErrors[ErrorType];
		CalculationProtocol.CalculationErrors.Insert(
			ErrorType,
			?(Not ValueIsFilled(ErrorsCount), 0, ErrorsCount) + 1);
		
		// Let's write a description of the error in the protocol.
		If ErrorType = Enums.TypesOfLotAccountingAndCostErrors.AnErrorOccurredWhenGeneratingRecordsInRegisters
		 And ValueIsFilled(FormattedTextForProtocol) Then
			
			// Since errors of this type are displayed not at the stage, but at the end of the protocol, then the name of the problematic stage should be specified in the error text.
			If CalculationProtocol.Stages.Count() > 0 Then
				StageName_ = CalculationProtocol.Stages[CalculationProtocol.Stages.Count()-1].PresentationStage;
				FormattedTextForProtocol = FormattedTextForProtocol + " (" + StageName_ + ")";
			EndIf;
			
			CalculationProtocol.MovementErrors.Add(FormattedTextForProtocol);
			
		ElsIf ErrorType = Enums.TypesOfLotAccountingAndCostErrors.AnErrorOccurredWhenWritingRecordsInRegisters
		 And ValueIsFilled(FormattedTextForProtocol) Then
			
			CalculationProtocol.RecordingErrors.Add(FormattedTextForProtocol);
			
		ElsIf ValueIsFilled(FormattedTextForProtocol) Then
			
			StageDescription = CurStageDescription(CalculationParameters);
			
			If StageDescription <> Undefined
			 And StageDescription.ErrorInformation_[ErrorType] = Undefined Then
				StageDescription.ErrorInformation_.Insert(ErrorType, New Array);
			EndIf;
			
			If Not (StrStartsWith(FormattedTextForProtocol, ServiceSymbol_WithoutNumbering())
					And StageDescription <> Undefined
			 		And ValueIsFilled(StageDescription.ErrorInformation_[ErrorType])
			 		And StageDescription.ErrorInformation_[ErrorType][0] = FormattedTextForProtocol) Then
				StageDescription.ErrorInformation_[ErrorType].Add(FormattedTextForProtocol);
			EndIf;
			
		EndIf;		
		
	EndIf;
	
	// Let's write a description of the error in the log.
	If ValueIsFilled(TextForLog_) Then
		
		WriteLogEvent(
			CostCalculationAppliedAlgorithms.NameOfErrorEventForLog(CalculationParameters),
			EventLogLevel.Error,
			,
			,
			ErrorTextPresentation(TextForLog_));
		
	EndIf;		
	
EndProcedure

#EndRegion


#Region EventLog

// Makes a log entry about the start of the stage execution.
//
Procedure MarkInLog(CalculationParameters, PresentationStage, Level = Undefined, Comment = "")
	
	If Not ValueIsFilled(Level) Then
		Level = EventLogLevel.Information;
	EndIf;
	
	If Not ValueIsFilled(Comment) Then
		Comment = NStr("vi = 'Bắt đầu kỳ.';
						|ru = 'Начало выполнения этапа.';
						|en = 'Step execution start.'; fa = 'Step execution start.';
						|it = 'Esecuzione della fase avviata.';
						|pl = 'Rozpoczęcie wykonania etapu.';
						|tr = 'Aşama gerçekleştirmenin başlangıcı.'", Common.DefaultLanguageCode());
	EndIf;
	
	WriteLogEvent(
		CostCalculationAppliedAlgorithms.EventLogEventName(
			CalculationParameters, NStr("vi = 'Công đoạn';
										|ru = 'Этап';
										|en = 'Stage'; fa = 'مرحله';
										|it = 'Fase';
										|pl = 'Stage';
										|tr = 'Aşama'", Common.DefaultLanguageCode()) + "." + PresentationStage),
		Level,
		,
		,
		Comment);
	
EndProcedure

#EndRegion

#Region PresentationAndOutputOfData

// Returns a representation of the time interval (start Time, end Time) and its % of the total calculation time.
//
Function RuntimePresentation(TimeDataSource, SourceOfTotalTimeData = Undefined)
	
	TimeDataStructure = New Structure("BeginTime, EndTime, TotalTime");
	FillPropertyValues(TimeDataStructure, TimeDataSource);
	
	If ValueIsFilled(TimeDataStructure.TotalTime) Then
		Seconds = TimeDataStructure.TotalTime / 1000;
	ElsIf ValueIsFilled(TimeDataStructure.BeginTime) And ValueIsFilled(TimeDataStructure.EndTime) Then
		Seconds = (TimeDataStructure.EndTime - TimeDataStructure.BeginTime) / 1000;
	Else
		Seconds = 0;
	EndIf;
	
	TimePresentation = TimePresentation(Seconds);
	
	If SourceOfTotalTimeData <> Undefined Then
		
		TimeDataStructure = New Structure("BeginTime, EndTime");
		FillPropertyValues(TimeDataStructure, SourceOfTotalTimeData);
		
		If ValueIsFilled(TimeDataStructure.BeginTime) And ValueIsFilled(TimeDataStructure.EndTime) Then
			
			TotalTime 			 = TimeDataStructure.EndTime - TimeDataStructure.BeginTime;
			PercentageOfTime 		 = Round(100 * Seconds / (?(TotalTime = 0, 1, TotalTime) / 1000), 2);
			TimePresentation = TimePresentation + " (" + ValuePresentation(PercentageOfTime) + "%)";
			
		EndIf;
		
	EndIf;
	
	Return TrimAll(TimePresentation);
	
EndFunction

// Returns a representation of the calculation month.
//
// Returns:
//	String - 
//
Function PresentationOfCalculationPeriod(CalculationParametersOrPeriod) Export
	
	If TypeOf(CalculationParametersOrPeriod) = Type("Structure") Then
		Date = CalculationParametersOrPeriod.PayrollPeriod.EndOfPeriod;
		MonthEndClosingMode = CalculationParametersOrPeriod.MonthEndClosingMode;
	Else
		Date = CalculationParametersOrPeriod;
		MonthEndClosingMode = Undefined;
	EndIf;
	
	If MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing Then
		PeriodPresentation = NStr("vi = 'từ %1 đến %2';
									|ru = 'с %1 по %2';
									|en = 'from %1 to %2'; fa = 'from %1 to %2';
									|it = 'da %1 fino a %2';
									|pl = 'od %1 do %2';
									|tr = '%1 itibaren %2 kadar'");
		PeriodPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			PeriodPresentation,
			Format(BegOfMonth(Date), "DLF=D"),
			Format(Date, "DLF=D"));
	Else
		PeriodPresentation = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(Date);
	EndIf;
	
	Return PeriodPresentation;
	
EndFunction

// Returns a representation of an arbitrary value.
// When using this function, all values of the same type will have the same formatting.
//
// Returns:
//	String - 
//
Function ValuePresentation(Value, PresentationOfDateAsCalculationPeriod = False) Export
	
	If TypeOf(Value) = Type("Boolean") Then
		
		Return Format(Value, NStr("vi = 'БЛ=Không; БИ=Có';
									|ru = 'БЛ=Нет; БИ=Да';
									|en = 'BF=No; BT=Yes'; fa = 'BF=خیر; BT=بله';
									|it = 'БЛ=No; БИ=Si';
									|pl = 'BF=Nie; BT=Tak';
									|tr = 'БЛ=Hayır; БИ=Evet'", Common.DefaultLanguageCode()));
		
	ElsIf TypeOf(Value) = Type("Number") Then 
		
		If Value <> 0 And Value > -0.001 And Value < 0.001 Then
			
			// Representation of small numbers
			
			Power 	  = 0;
			NewValue = Value;
			
			While NewValue > -1 And NewValue < 1 Do
				Power = Power + 1;
				NewValue = NewValue * 10;
			EndDo;
			
			Return TrimAll(NewValue) + " * 10^-" + TrimAll(Power);
			
		EndIf;
		
	ElsIf TypeOf(Value) = Type("Date") And PresentationOfDateAsCalculationPeriod Then 
		
		Return PresentationOfCalculationPeriod(Value);
		
	ElsIf TypeOf(Value) = Type("EnumRef.InventoryValuationMethods") Then
		
		If Not ValueIsFilled(Value) Then
			Return "<" + NStr("vi = 'Không sử dụng ';
								|ru = 'Не используется';
								|en = 'Not used'; fa = 'استفاده نمی‌شود';
								|it = 'Non viene utilizzato';
								|pl = 'Nie używane';
								|tr = 'Kullanılmıyor'", Common.DefaultLanguageCode()) + ">";
		EndIf;
		
	ElsIf TypeOf(Value) = Type("EnumRef.LotRecordTypes") Then
		
		If Not ValueIsFilled(Value) Then
			Return "<" + NStr("vi = 'Dạng biểu ghi lô trống';
								|ru = 'Пустой тип записи партии';
								|en = 'Empty lot record type'; fa = 'Empty lot record type';
								|it = 'Tipo della registrazione del lotto vuoto';
								|pl = 'Pusty typ zapisu partii';
								|tr = 'Boş lot kayıt türü'", Common.DefaultLanguageCode()) + ">";
		EndIf;
		
	EndIf;
	
	Return TrimAll(Value);
	
EndFunction

// Returns the time representation in hours / minutes/seconds.
//
// Returns:
//	String - 
//
Function TimePresentation(Value, WithFractionsOfSeconds = True) Export
	
	Seconds = Value;
	
	Hours1 = Int(Seconds / 3600);
	Seconds = Seconds - Hours1*3600;
	
	Minutes1  = Int(Seconds / 60);
	Seconds = Round(Seconds - Minutes1*60, ?(WithFractionsOfSeconds, 3, 0));
	
	TimePresentation = ""
		+ ?(Hours1 = 0, "", ValuePresentation(Hours1) + " " + NStr("vi = 'giờ';
																	|ru = 'ч.';
																	|en = 'h'; fa = 'ساعت';
																	|it = 'h.';
																	|pl = 'g.';
																	|tr = 'sa.'", Common.DefaultLanguageCode()) + " ")
		+ ?(Minutes1 = 0, "", ValuePresentation(Minutes1) + " " + NStr("vi = 'phút';
																		|ru = 'мин.';
																		|en = 'min.'; fa = 'دقیقه';
																		|it = 'min.';
																		|pl = 'min.';
																		|tr = 'dk.'", Common.DefaultLanguageCode()) + " ")
		+ ValuePresentation(Seconds) + " " + NStr("vi = 'giây';
													|ru = 'сек.';
													|en = 'sec'; fa = 'ثانیه';
													|it = 'sec.';
													|pl = 'sek.';
													|tr = 'sn.'", Common.DefaultLanguageCode());
	
	Return TrimAll(TimePresentation);
	
EndFunction

// Returns a representation of multi-line text-adds padding for each line.
//
// Returns:
//	String - 
//
Function PresentationOfMultilineText(Value, Val ParagraphFormatText = "",
			DoNotOutputEmptyLines = True, RemoveOldFormatting = True) Export
	
	If Not ValueIsFilled(Value) Then
		Return "";
	EndIf;
	
	TextPresentation_ = "";
	ParagraphFormatText  = StrReplace(ParagraphFormatText, "	", "    "); // replace tabs with spaces
	TextIndentation			= Chars.LF;
	
	For NS = 1 To StrLen(ParagraphFormatText) Do
		TextIndentation = TextIndentation + " "; // indentation for the 2nd and next lines
	EndDo;
	
	For NS = 1 To StrLineCount(Value) Do
		
		If RemoveOldFormatting Then
			CurrentRow = TrimAll(StrGetLine(Value, NS));
		Else
			CurrentRow = StrGetLine(Value, NS);
		EndIf;
		
		If DoNotOutputEmptyLines And Not ValueIsFilled(CurrentRow) Then
			Continue;
		EndIf;
		
		TextPresentation_ = TextPresentation_
			+ ?(Not ValueIsFilled(TextPresentation_), ParagraphFormatText, TextIndentation) + CurrentRow;
		
	EndDo;
	
	Return TextPresentation_;
	
EndFunction

// Returns a representation of the error message text.
//
// Returns:
//	String - 
//
Function ErrorTextPresentation(Value) Export
	
	If Not ValueIsFilled(Value) Then
		Return "";
	EndIf;
	
	TextPresentation_ = "";
	TextIndentation 		= Chars.LF;
	TextSeparator_ 	= "}:";
	
	For NS = 1 To StrLineCount(Value) Do
		
		CurrentRow = TrimAll(StrGetLine(Value, NS));
		
		If Not ValueIsFilled(CurrentRow) Then
			Continue;
		EndIf;
		
		If StrFind(Lower(CurrentRow), Lower("Raise")) = 1
		 Or StrFind(Lower(CurrentRow), Lower("Raise")) = 1 Then
			Continue; // the current line is superfluous, uninformative - we caused the error ourselves
		EndIf;
		
		If Left(CurrentRow, StrLen(ServiceSymbol_BulletedList())) = ServiceSymbol_BulletedList() Then
			TextIndentation = Chars.LF; // the error description contains a list - we clear the formatting to output the next list item
			CurrentRow = "- " + Mid(CurrentRow, 2);
		EndIf;
		
		While ValueIsFilled(CurrentRow) And StrFind(CurrentRow, TextSeparator_) > 0 Do
			
			CurSubstring = Left(CurrentRow, StrFind(CurrentRow, TextSeparator_) + StrLen(TextSeparator_) - 1); // the location of the error in the code
			CurrentRow 	 = TrimAll(Mid(CurrentRow, StrLen(CurSubstring) + 1)); // the rest of the line
			
			TextPresentation_ = TextPresentation_
				+ ?(Not ValueIsFilled(TextPresentation_), "", TextIndentation) + CurSubstring; // the left part of the current line
			
			TextIndentation = TextIndentation + "    "; // increase the indentation of the rest of the error text
			
		EndDo;
		
		If ValueIsFilled(CurrentRow) Then
			TextPresentation_ = TextPresentation_
				+ ?(Not ValueIsFilled(TextPresentation_), "", TextIndentation) + CurrentRow; // the remainder of the current line
		EndIf;
		
	EndDo;
	
	Return TextPresentation_;
	
EndFunction

// Returns a view of the list of errors recorded during the calculation.
//
Function PresentationOfCalculationErrors(CalculationProtocol, Title = Undefined, Separator = Undefined)
	
	If Title = Undefined Then
		Title = NStr("vi = 'Đã tìm thấy lỗi';
					|ru = 'Обнаружены ошибки';
					|en = 'Errors are found'; fa = 'Errors are found';
					|it = 'Errori trovati';
					|pl = 'Wykryto błędy';
					|tr = 'Hatalar bulundu'", Common.DefaultLanguageCode());
	EndIf;
	
	If Separator = Undefined Then
		Separator = ", ";
	EndIf;
	
	MultiLineSeparator = (StrFind(Separator, Chars.LF) > 0);
	
	ErrorPresentation_ = "";
	
	ErrorsTypes = New Map;
    ErrorsTypes.Insert(Enums.TypesOfLotAccountingAndCostErrors.ErrorInSourceDataForCalculation,
        NStr("vi = 'trong dữ liệu nguồn để tính toán';
			|ru = 'в исходных данных для расчета';
			|en = 'in source data for calculation'; fa = 'in source data for calculation';
			|it = 'nei dati sorgente per il calcolo';
			|pl = 'w wyjściowych danych do rozliczenia';
			|tr = 'hesaplama için kaynak verilerde'", Common.DefaultLanguageCode()));
    ErrorsTypes.Insert(Enums.TypesOfLotAccountingAndCostErrors.ErrorOfInitializingCalculationParameters,
        NStr("vi = 'khi khởi tạo tham số tính toán';
			|ru = 'при инициализации параметров расчета';
			|en = 'when initializing calculation parameters'; fa = 'when initializing calculation parameters';
			|it = 'all''inizializzazione dei parametri di calcolo';
			|pl = 'podczas inicjalizacji parametrów rozliczenia';
			|tr = 'hesaplama parametrelerini başlatırken'", Common.DefaultLanguageCode()));
    ErrorsTypes.Insert(Enums.TypesOfLotAccountingAndCostErrors.CompanyAccountingPolicyError,
        NStr("vi = 'trong chính sách kế toán của các doanh nghiệp';
			|ru = 'в учетных политиках организаций';
			|en = 'in accounting policies of companies'; fa = 'in accounting policies of companies';
			|it = 'nelle politiche contabili delle aziende';
			|pl = 'w politykach ewidencyjnych firm';
			|tr = 'iş yeri muhasebe politikaları'", Common.DefaultLanguageCode()));
    ErrorsTypes.Insert(Enums.TypesOfLotAccountingAndCostErrors.AnErrorOccurredWhenRestoringDocumentRegisterRecords,
        NStr("vi = 'khi khôi phục các bản ghi kết chuyển của chứng từ';
			|ru = 'при восстановлении движений документов';
			|en = 'when restoring migrations of documents'; fa = 'when restoring migrations of documents';
			|it = 'al ripristino dei movimentazioni dei documenti';
			|pl = 'podczas przywrócenia ruchów dokumentów';
			|tr = 'belge kayıtları geri yüklenirken'", Common.DefaultLanguageCode()));
    ErrorsTypes.Insert(Enums.TypesOfLotAccountingAndCostErrors.ErrorOfCostCalculationDocumentsInInitializing,
        NStr("vi = 'khi khởi tạo chứng từ tính giá vốn';
			|ru = 'при инициализации документов расчета себестоимости';
			|en = 'when initializing cost calculation documents'; fa = 'when initializing cost calculation documents';
			|it = 'all''inizializzazione dei documenti di calcolo del prezzo di costo';
			|pl = 'podczas inicjalizacji dokumentów rozliczenia kosztów własnych';
			|tr = 'maliyet hesaplama belgelerini başlatırken'", Common.DefaultLanguageCode()));
    ErrorsTypes.Insert(Enums.TypesOfLotAccountingAndCostErrors.ErrorOccurredDuringLotAlocation,
        NStr("vi = 'khi phân bổ lô';
			|ru = 'при распределении партий';
			|en = 'when allocating lots'; fa = 'when allocating lots';
			|it = 'alla ripartizione dei lotti';
			|pl = 'podczas podziału partii';
			|tr = 'lot dağıtımı sırasında'", Common.DefaultLanguageCode()));
    ErrorsTypes.Insert(Enums.TypesOfLotAccountingAndCostErrors.VATAllocationError,
        NStr("vi = 'khi phân bổ thuế GTGT';
			|ru = 'при распределении НДС';
			|en = 'when allocating VAT'; fa = 'when allocating VAT';
			|it = 'alla ripartizione dell''IVA';
			|pl = 'podczas podziału VAT';
			|tr = 'KDV dağıtımı sırasında'", Common.DefaultLanguageCode()));
    ErrorsTypes.Insert(Enums.TypesOfLotAccountingAndCostErrors.ErrorOccurredWhenPerformingPeriodEndTransactions,
        NStr("vi = 'khi thực hiện các hoạt động đóng cửa theo lịch trình liên quan trong tháng';
			|ru = 'при выполнении связанных регламентных операций закрытия месяца';
			|en = 'when performing related by-the-book month-end closing transactions'; fa = 'when performing related by-the-book month-end closing transactions';
			|it = 'all''esecuzione delle operazioni di routine correlate di chiusura del mese';
			|pl = 'podczas wykonywania planowych operacji zamknięcia miesiąca';
			|tr = 'ilgili programlı ay sonu kapanış işlemlerini gerçekleştirirken'", Common.DefaultLanguageCode()));
    ErrorsTypes.Insert(Enums.TypesOfLotAccountingAndCostErrors.AnErrorOccurredWhenGeneratingRecordsInRegisters,
        NStr("vi = 'khi tạo các bản ghi kết chuyển theo biểu ghi';
			|ru = 'при формировании движений по регистрам';
			|en = 'when forming migrations by registers'; fa = 'when forming migrations by registers';
			|it = 'alla generazione dei movimenti per registri';
			|pl = 'podczas tworzenia ruchów według rejestrów';
			|tr = 'kayıtlar üzerinde hareketler oluştururken'", Common.DefaultLanguageCode()));
    ErrorsTypes.Insert(Enums.TypesOfLotAccountingAndCostErrors.AnErrorOccurredWhenWritingRecordsInRegisters,
        NStr("vi = 'khi ghi bản ghi kết chuyển theo biểu ghi';
			|ru = 'при записи движений по регистрам';
			|en = 'when saving migrations by registers'; fa = 'when saving migrations by registers';
			|it = 'al salvataggio per registri';
			|pl = 'podczas zapisu ruchów według rejestrów';
			|tr = 'hareketleri kayıt defterlerine kaydederken'", Common.DefaultLanguageCode()));
    ErrorsTypes.Insert(Enums.TypesOfLotAccountingAndCostErrors.ErrorInBalanceAfterCalculation,
        NStr("vi = 'trong số dư sau khi tính toán';
			|ru = 'в остатках после расчета';
			|en = 'in balance after calculation'; fa = 'in balance after calculation';
			|it = 'nei saldi dopo il calcolo';
			|pl = 'w pozostałościach po rozliczeniu';
			|tr = 'hesaplama sonrası bakiyelerde'", Common.DefaultLanguageCode()));
    ErrorsTypes.Insert(Enums.TypesOfLotAccountingAndCostErrors.RunTimeError,
        NStr("vi = 'khi thực thi mã (lỗi thời gian chạy)';
			|ru = 'при выполнения кода (run-time error)';
			|en = 'when performing code (run-time error)'; fa = 'when performing code (run-time error)';
			|it = 'all''esecuzione del codice (run-time error)';
			|pl = 'podczas wykonywania kodu (run-time error)';
			|tr = 'kod gerçekleştirme sırasında (run-time error)'", Common.DefaultLanguageCode()));
    ErrorsTypes.Insert(Enums.TypesOfLotAccountingAndCostErrors.ErrorInOpeningBalanceLotAccounting22,
        NStr("vi = 'trong số dư ban đầu khi chuyển sang phiên bản kế toán hàng loạt 2.2';
			|ru = 'в начальных остатках при переходе на партионный учет версии 2.2';
			|en = 'in opening balance when migrating to lot accounting 2.2'; fa = 'in opening balance when migrating to lot accounting 2.2';
			|it = 'nei saldi iniziali nella transizione alla contabilità per lotti della versione 2.2';
			|pl = 'w początkowych pozostałościach podczas przejścia na ewidencję partii wersji 2.2';
			|tr = 'lot muhasebesi sürüm 2.2''ye geçerken açılış bakiyelerinde'", Common.DefaultLanguageCode()));	
	
	// We will output the error types in the same order in which they are present in the metadata.
	For Each MetaValue In Metadata.Enums.TypesOfLotAccountingAndCostErrors.EnumValues Do
		
		If ValueIsFilled(CalculationProtocol.CalculationErrors[Enums.TypesOfLotAccountingAndCostErrors[MetaValue.Name]]) Then 
			
			CurrentError = ErrorsTypes.Get(Enums.TypesOfLotAccountingAndCostErrors[MetaValue.Name]);
			
			If Not ValueIsFilled(CurrentError) Then
				CurrentError = MetaValue.Synonym;
			EndIf;
			
			ErrorPresentation_ = ErrorPresentation_ + ?(ErrorPresentation_ = "", "", Separator) + TrimAll(CurrentError);
			
		EndIf;
		
	EndDo;
	
	If ValueIsFilled(ErrorPresentation_) Then
		ErrorPresentation_ =
			Title + ?(MultiLineSeparator, Separator, " ")
			+ ErrorPresentation_ + ?(MultiLineSeparator, "", ".");
	EndIf;
	
	Return ErrorPresentation_;
	
EndFunction

// Returns a service character that allows you to skip numbering for the" header " of the Protocol error list.
//
// Returns:
//	String - 
//
Function ServiceSymbol_WithoutNumbering() Export
	Return "#";
EndFunction

// Returns a service symbol that allows you to create a bulleted list of errors.
//
// Returns:
//	String - 
//
Function ServiceSymbol_BulletedList() Export
	Return "~";
EndFunction

// Returns a string that separates the parts of the calculation Protocol.
//
Function ProtocolPartSeparator()
	Return "=================================================================================";
EndFunction

// Returns the Protocol header for displaying it on the screen.
//
// Returns:
//	String - 
//
Function OutputProtocolHeader(CalculationPeriod) Export
	
	TextTitle_ = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Giao thức tính toán kỳ %1';
			|ru = 'Протокол расчета периода %1';
			|en = 'Period calculation protocol %1'; fa = 'Period calculation protocol %1';
			|it = 'Protocollo di calcolo del periodo %1';
			|pl = 'Protokół obliczenia okresu %1';
			|tr = 'Dönem hesaplama protokolü %1'", Common.DefaultLanguageCode()),
		PresentationOfCalculationPeriod(CalculationPeriod));
	
	Return TextTitle_;
	
EndFunction

	
// Outputs error information to the log and duplicates it to the log.
//
Procedure DisplayErrorInformation(CalculationParameters, Protocol, ErrorData_, Title, PresentationStage = Undefined)
	
	If Not ValueIsFilled(ErrorData_) Then
		Return;
	EndIf;
	
	If TypeOf(ErrorData_) = Type("Array") Then
		ErrorMatching = New Map;
		ErrorMatching.Insert(Enums.TypesOfLotAccountingAndCostErrors.EmptyRef(), ErrorData_);
	Else
		ErrorMatching = ErrorData_;
	EndIf;
	
	ErrorsDescription   = "";
	DescriptionOfLFErrors = "";
	ThereAreErrorsForEL  = False;
	ErrorNumber      = 0;
	
	For Each KeyAndValue In ErrorMatching Do
		
		If ErrorMatching.Count() > 1 Then
			// If there are several types of errors, then we will output the text-grouping by type.
			ErrorsDescription = ErrorsDescription + ?(ErrorsDescription = "", "", "
				|") + NStr("vi = 'Loại lỗi';
							|ru = 'Тип ошибки';
							|en = 'Error type'; fa = 'نوع خطا';
							|it = 'Tipo dell''errore';
							|pl = 'Typ błędu';
							|tr = 'Hata türü'", Common.DefaultLanguageCode()) + ": """ + ValuePresentation(KeyAndValue.Key) + """.";
			
			If KeyAndValue.Key <> Enums.TypesOfLotAccountingAndCostErrors.ErrorInBalanceAfterCalculation
			 And KeyAndValue.Key <> Enums.TypesOfLotAccountingAndCostErrors.ErrorInSourceDataForCalculation Then
				// Errors of the above types will be recorded in the registration Log by the month closing MECHANISM
				DescriptionOfLFErrors = DescriptionOfLFErrors + ?(DescriptionOfLFErrors = "", "", "
					|") + NStr("vi = 'Loại lỗi';
								|ru = 'Тип ошибки';
								|en = 'Error type'; fa = 'نوع خطا';
								|it = 'Tipo dell''errore';
								|pl = 'Typ błędu';
								|tr = 'Hata türü'", Common.DefaultLanguageCode()) + ": """ + ValuePresentation(KeyAndValue.Key) + """.";
			EndIf;
			
		EndIf;
		
		For Each ErrorText In KeyAndValue.Value Do
			
			NumberingIsRequired = (Left(ErrorText, StrLen(ServiceSymbol_WithoutNumbering())) <> ServiceSymbol_WithoutNumbering());
			
			If NumberingIsRequired Then 
				ErrorNumber = ErrorNumber + 1;
				NumberingPrefix = "	" + ValuePresentation(ErrorNumber) + ". ";
			Else
				// At the beginning of the grouping lines, you can specify a special # character, and such lines will not be numbered when output.
				ErrorText = Mid(ErrorText, 2);
				NumberingPrefix = "";
			EndIf;
			
			ErrorsDescription = ErrorsDescription + ?(ErrorsDescription = "", "", "
				|") + PresentationOfMultilineText(ErrorText, ?(ErrorMatching.Count() > 1, "	", "") + NumberingPrefix, False, False);
			
			If KeyAndValue.Key <> Enums.TypesOfLotAccountingAndCostErrors.ErrorInBalanceAfterCalculation
			 And KeyAndValue.Key <> Enums.TypesOfLotAccountingAndCostErrors.ErrorInSourceDataForCalculation Then
				// Errors of the above types will be recorded in the registration Log by the month closing MECHANISM
				ThereAreErrorsForEL = True;
				DescriptionOfLFErrors = DescriptionOfLFErrors + ?(DescriptionOfLFErrors = "", "", "
					|") + PresentationOfMultilineText(ErrorText, ?(ErrorMatching.Count() > 1, "	", "") + NumberingPrefix, False, False);
			EndIf;
			
		EndDo;
		
	EndDo;
	
	ErrorsDescription =
		Title
		+ ?(ErrorNumber > 0,  " (" + ValuePresentation(ErrorNumber) + " " + NStr("vi = 'dấu';
																				|ru = 'шт.';
																				|en = 'pcs.'; fa = 'عدد';
																				|it = 'pz.';
																				|pl = 'szt.';
																				|tr = 'parça'", Common.DefaultLanguageCode()) + ")", "")
		+ " !" + Chars.LF + ErrorsDescription;
	
	Protocol.AddLine(ErrorsDescription);
	
	If ThereAreErrorsForEL Then
		
		DescriptionOfLFErrors =
			Title
			+ ?(ErrorNumber > 0,  " (" + ValuePresentation(ErrorNumber) + " " + NStr("vi = 'chiếc';
																					|ru = 'шт.';
																					|en = 'pcs.'; fa = 'عدد';
																					|it = 'шт.';
																					|pl = 'szt.';
																					|tr = 'parça'", Common.DefaultLanguageCode()) + ")", "")
			+ " !" + Chars.LF + DescriptionOfLFErrors;
		
		If ValueIsFilled(PresentationStage) Then
			DescriptionOfLFErrors = PresentationStage + Chars.LF + DescriptionOfLFErrors;
		EndIf;
		
		If CalculationParameters.CalculationProtocol.CalculationIsCompleted Then
			WriteLogEvent(
				CostCalculationAppliedAlgorithms.NameOfErrorEventForLog(CalculationParameters), 
				EventLogLevel.Error,,,
				DescriptionOfLFErrors);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Performance

Procedure StartTimeMeasurement(CalculationParameters) Export
	
	If CalculationParameters.Property("MeasurementDetails") Then
		// Regular call from the batch accounting mechanism version 2.1.
		DescriptionOfPerformanceMeasurement = CalculationParameters.MeasurementDetails;
	ElsIf CalculationParameters.CalculationOption = Enums.LotAndCostCalculationOptions.LotsAndCost Then
		DescriptionOfPerformanceMeasurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
			"MonthEndTransactions.CalculationOfBatchesAndCosts22PlatformService");
	Else
		Return;
	EndIf;
	
	CalculationParameters.Insert("Performance", New Structure);
	
	CalculationParameters.Performance.Insert("DescriptionOfPerformanceMeasurement", DescriptionOfPerformanceMeasurement);
	CalculationParameters.Performance.Insert("DataVolume", 0);
	CalculationParameters.Performance.Insert("StageName", CalculationParameters.PresentationStage);
	
EndProcedure

Procedure EndTimeMeasurement(CalculationParameters) Export
	
	If Not CalculationParameters.Property("Performance") Then
		Return;
	EndIf;
	
	If CalculationParameters.Property("MeasurementDetails") Then
		// The measurement is started "from the outside" - it should also end there.
		RecordTimeMeasurement(CalculationParameters);
	Else
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(
			CalculationParameters.Performance.DescriptionOfPerformanceMeasurement,
			CalculationParameters.Performance.DataVolume);
	EndIf;
	
	CalculationParameters.Delete("Performance");
	CalculationParameters.Delete("MeasurementDetails");
	
EndProcedure

Procedure RecordTimeMeasurement(CalculationParameters) Export
	
	If Not CalculationParameters.Property("Performance") Then
		Return;
	EndIf;
	
	StageDescription = CurStageDescription(CalculationParameters);
	
	If Not ValueIsFilled(StageDescription) Then
		Return;
	EndIf;
	
	If CalculationParameters.Performance.DataVolume = 0 Then
		CalculationParameters.Performance.DataVolume = 1;
	EndIf;
	
	StageDescription.DataVolume = StageDescription.DataVolume + CalculationParameters.Performance.DataVolume;
	
	PerformanceMonitor.FixTimeConsumingOperationMeasure(
		CalculationParameters.Performance.DescriptionOfPerformanceMeasurement,
		CalculationParameters.Performance.DataVolume,
		CalculationParameters.Performance.StageName);
	
	CalculationParameters.Performance.DataVolume = 0;
	
EndProcedure

Procedure IncreaseAmountOfProcessedDataForMeasurement(CalculationParameters, DataVolume) Export
	
	If Not CalculationParameters.Property("Performance") Then
		Return;
	EndIf;
	
	CalculationParameters.Performance.DataVolume =
		CalculationParameters.Performance.DataVolume + ?(DataVolume <= 0, 1, DataVolume);
	
EndProcedure

#EndRegion

#Region PresentationAndOutputOfData

Function MakeRequestWithMeasurements(CalculationParameters, RequestForMeasurement) Export
	
	StageDescription 	= CurStageDescription(CalculationParameters);
	
	MeasurementsTable = New ValueTable;
	MeasurementsTable.Columns.Add("TempTableName", New TypeDescription("String"));
	MeasurementsTable.Columns.Add("DestroyingTable",  New TypeDescription("Boolean"));
	MeasurementsTable.Columns.Add("BeginTime", 		   New TypeDescription("Date"));
	MeasurementsTable.Columns.Add("Duration", 	   New TypeDescription("Number"));
	MeasurementsTable.Columns.Add("ResultSize",    New TypeDescription("Number"));
	
	QueryResult   = New Array;
	OldRequestText = RequestForMeasurement.Text;
	
	If RequestForMeasurement.TempTablesManager = Undefined Then
		InterimTTManager = New TempTablesManager;
		RequestForMeasurement.TempTablesManager = InterimTTManager;
	Else
		InterimTTManager = Undefined;
	EndIf;
	
	RequestDiagramForMeasurement = New QuerySchema;
	RequestDiagramForMeasurement.SetQueryText(OldRequestText);
	
	For Each CurrentQuery In RequestDiagramForMeasurement.QueryBatch Do
		
		TempTableName = "";
		
		NewRow = MeasurementsTable.Add();
		NewRow.DestroyingTable = (TypeOf(CurrentQuery) = Type("QuerySchemaTableDropQuery"));
		
		If NewRow.DestroyingTable Then
			NewRow.TempTableName = CurrentQuery.TableName;
			RequestForMeasurement.Text = "DROP " + CurrentQuery.TableName;
		Else
			NewRow.TempTableName = CurrentQuery.PlacementTable;
			RequestForMeasurement.Text = CurrentQuery.GetQueryText();
		EndIf;
		
		NewRow.BeginTime = CurrentSessionDate();
		BeginTime = CurrentUniversalDateInMilliseconds();
		
		CurQueryResult = RequestForMeasurement.Execute();
		
		EndTime = CurrentUniversalDateInMilliseconds();
		NewRow.Duration = EndTime - BeginTime;
		
		If NewRow.DestroyingTable Then
			
			TempTableName = "_Drop_" + CurrentQuery.TableName;
			QueryResult.Add(Undefined);
			
		ElsIf ValueIsFilled(NewRow.TempTableName) Then
			
			TempTableName = NewRow.TempTableName;
			
			QueryResult.Add(Undefined);
			
			NewRow.ResultSize = CurQueryResult.Unload()[0][0];
			
		Else
			
			TempTableName = "_Select_";
			
			CurQuerySelection = CurQueryResult.Select();
			QueryResult.Add(CurQuerySelection);
			
			NewRow.ResultSize = CurQuerySelection.Count();
			
		EndIf;
		
		If Not StageDescription.TemporaryTable.Property(TempTableName) Then
			CurTemporaryTable = New Array;
		Else
			CurTemporaryTable = StageDescription.TemporaryTable[TempTableName]; // Array
		EndIf;
	
		DescriptionOfTheTemporaryTable = New Structure;
		DescriptionOfTheTemporaryTable.Insert("RowsCount", NewRow.ResultSize);
		DescriptionOfTheTemporaryTable.Insert("BeginTime", 	 BeginTime);
		DescriptionOfTheTemporaryTable.Insert("EndTime",  EndTime);
		DescriptionOfTheTemporaryTable.Insert("Explanation", 		 "");
		DescriptionOfTheTemporaryTable.Insert("RawData",  "");
		
		CurTemporaryTable.Add(DescriptionOfTheTemporaryTable);
		StageDescription.TemporaryTable.Insert(TempTableName, CurTemporaryTable);
		
	EndDo;
	
	If InterimTTManager <> Undefined Then
		RequestForMeasurement.TempTablesManager = Undefined;
		InterimTTManager.Close();
	EndIf;
	
	RequestForMeasurement.Text = OldRequestText;
	
	If QueryResult.Count() = 0 Then
		Return Undefined;
	ElsIf QueryResult.Count() = 1 Then
		Return QueryResult[0];
	EndIf;
	
	Return QueryResult;
	
EndFunction

#EndRegion

#EndRegion
