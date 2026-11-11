#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	CheckNeedToResetCacheOfBudgetTypes(Cancel);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If IsFolder Then
		Return;
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
	If Ref = Catalogs.BudgetingScenarios.ActualData
		Or Ref = Catalogs.BudgetingScenarios.BudgetFulfillment Then
		NotCheckedAttributeArray.Add("Periodicity");
		NotCheckedAttributeArray.Add("Currency");
	EndIf;
	
	If Not UseExchangeRatesOfAnotherScenario Then
		NotCheckedAttributeArray.Add("RateScenario");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If Not GetFunctionalOption("UseMultipleCurrencies")
		And Not IsFolder
		And Not ValueIsFilled(Currency) Then
		
		Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(Currency);
		If Not ValueIsFilled(Currency) Then
			Raise NStr("vi = 'Không thể điền vào trường Tiền tệ. Đặt tiền tệ của kế toán quản trị!';
						|ru = 'Не удалось заполнить поле ""Валюта"". Установите валюту управленческого учета!';
						|en = 'Failed to fill in field ""Currency"". Set management accounting currency.'; fa = 'Failed to fill in field ""Currency"". Set management accounting currency.';
						|it = 'Non è stato possibile compilare il campo ""Valuta"". Impostare la valuta della contabilità gestionale!';
						|pl = 'Wypełnianie pola ""Валюта"" nie powiodło się. Ustaw walutę ewidencji zarządczej!';
						|tr = '""Para birimi"" alanı doldurulamadı. Yönetim muhasebesi para birimini ayarlayın!'");
		EndIf;
		
	EndIf;
	
	If Not IsFolder Then
		TheBaseCurrencyOfTheExchangeRates = SettingsValueCached.DefaultBaseCurrency();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckNeedToResetCacheOfBudgetTypes(Cancel)
	If Not Cancel Then
		If Ref = Catalogs.BudgetingScenarios.ActualData
		 Or Ref = Catalogs.BudgetingScenarios.BudgetFulfillment Then
			If Parent <> Common.ObjectAttributeValue(Ref, "Parent") Then
				// If the parent changes for predefined elements, then it is necessary to reset the cache of the budget types settings,
				// because the settings may specify selection from the scenario with the type of comparison "in a group" or "in a group from a list",
				// which may affect the need to obtain actual data.
				Try
					Set = InformationRegisters.CacheOfAuxiliaryBudgetProfileData.CreateRecordSet();
					Set.Write(True);
				Except
					LanguageCode = Common.DefaultLanguageCode();
					EventName = NStr("vi = 'Ghi kịch bản';
									|ru = 'Запись сценария';
									|en = 'Record scenario'; fa = 'Record scenario';
									|it = 'Registrare script';
									|pl = 'Wpis scenariusza';
									|tr = 'Senaryo kaydı'", LanguageCode);
					TextOfMessageLR = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Không thể xóa bộ đệm dữ liệu phụ do: %1';
							|ru = 'Не удалось очистить кэш вспомогательных данных по причине: %1';
							|en = 'Cannot clear auxiliary data cache. Reason: %1'; fa = 'Cannot clear auxiliary data cache. Reason: %1';
							|it = 'Non è stato possibile cancellare la cache di dati ausiliari a causa di:%1';
							|pl = 'Oczyszczanie bufora danych pomocniczych nie powiodło się z powodu: %1';
							|tr = 'Servis verileri önbellekten şu sebeple temizlenemedi: %1'", LanguageCode),
						ErrorProcessing.DetailErrorDescription(ErrorInfo()));
					MessageText   = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Không thể xóa bộ đệm dữ liệu phụ do: %1';
							|ru = 'Не удалось очистить кэш вспомогательных данных по причине: %1';
							|en = 'Cannot clear auxiliary data cache. Reason: %1'; fa = 'Cannot clear auxiliary data cache. Reason: %1';
							|it = 'Non è stato possibile cancellare la cache di dati ausiliari a causa di:%1';
							|pl = 'Oczyszczanie bufora danych pomocniczych nie powiodło się z powodu: %1';
							|tr = 'Servis verileri önbellekten şu sebeple temizlenemedi: %1'"),
						ErrorProcessing.DetailErrorDescription(ErrorInfo()));
					WriteLogEvent(EventName,
					                         EventLogLevel.Error,,,
					                         TextOfMessageLR);
					Common.MessageToUser(MessageText,,,, Cancel);
				EndTry;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#EndIf
