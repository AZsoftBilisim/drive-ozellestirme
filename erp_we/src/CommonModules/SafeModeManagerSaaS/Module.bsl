////////////////////////////////////////////////////////////////////////////////
// 
//  Support for security profiles.
//
////////////////////////////////////////////////////////////////////////////////
// @strict-types

#Region Public

// Returns the execution mode of the external module in the service model.
//
// Parameters:
//  ExternalModule - AnyRef - Ref
//
// Returns:
//	String - execution mode of the external module.
//
Function ExternalModuleExecutionMode(Val ExternalModule) Export
	
	If Common.DataSeparationEnabled() Then
		
		Var_Key = SafeModeManagerInternalSaaS.RegisterKeyByReference(ExternalModule);
		
		If Common.SeparatedDataUsageAvailable() Then
			
			Mode = InformationRegisters.DataAreaExternalModulesAttachmentModes.ExternalModuleExecutionMode(
				Var_Key.Type, Var_Key.Id);
			
			If Mode = Undefined Then
				
				Mode = InformationRegisters.ExternalModulesConnectionOptionsSaaS.ExternalModuleExecutionMode(
					Var_Key.Type, Var_Key.Id);
				
				Return Mode;
				
			Else
				
				Return Mode;
				
			EndIf;
			
		Else
			
			Mode = InformationRegisters.ExternalModulesConnectionOptionsSaaS.ExternalModuleExecutionMode(
				Var_Key.Type, Var_Key.Id);
			
			Return Mode;
			
		EndIf;
		
	Else
		Raise NStr("vi = 'Hàm không có ý định được gọi trong CSTT, trong đó phân chia theo vùng dữ liệu bị tắt';
					|ru = 'Функция не предназначена для вызова в информационной базе, в которой выключено разделение по областям данных';
					|en = 'The function cannot be called in the Infobase with disabled separation by data areas'; fa = 'The function cannot be called in the Infobase with disabled separation by data areas';
					|it = 'La funzione non è destinata a essere richiamata nel database con condivisione per aree dati disattivata';
					|pl = 'Funkcja nie jest przeznaczona do wywoływania w bazie danych informacyjnych, w której wyłączone jest rozdzielenie w obszarach danych';
					|tr = 'İşlev, veri alanlarına göre bölmenin devre dışı bırakıldığı infobase''te çağrılmak üzere tasarlanmamıştır.'");
	EndIf;
	
EndFunction

#EndRegion