
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If IsFolder(CommandParameter) Then
		ShowMessageBox(,NStr("vi = 'Đặt giá trị cho các nhóm biện pháp tài chính không được hỗ trợ.';
							|ru = 'Установка значений для групп финансовых показателей не поддерживается.';
							|en = 'Cannot set values for financial indicator groups.'; fa = 'Cannot set values for financial indicator groups.';
							|it = 'Impostazione dei valori per i gruppi degli indici finanziari non viene supportata.';
							|pl = 'Ustawianie Konfiguracja wartości dla grup wskaźników finansowych nie jest obsługiwane.';
							|tr = 'Finansal göstergeler grubu için değer kurulumu desteklenmiyor.'"));
		Return;
	EndIf;
	
	InstallationParameters = New Structure();
	If TypeOf(CommandParameter) = Type("CatalogRef.NonFinancialItemsOfBudgets") Then
		FillingValues = New Structure("NonFinancialItem, OperationKind", CommandParameter,
			PredefinedValue(
			"Enum.OperationKindsOfSettingOfNonFinancialItemValues.EnterIndicatorValue"));
	Else
		FillingValues = New Structure("InputTemplate, OperationKind", CommandParameter, PredefinedValue(
			"Enum.OperationKindsOfSettingOfNonFinancialItemValues.EnterValuesFromTemplate"));
	EndIf;
	InstallationParameters.Insert("FillingValues", FillingValues);
	
	OpenForm("Document.SetValuesForNonFinancialItems.Form.DocumentForm", InstallationParameters,,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function IsFolder(Ref)
	Return Ref.IsFolder;
EndFunction

#EndRegion