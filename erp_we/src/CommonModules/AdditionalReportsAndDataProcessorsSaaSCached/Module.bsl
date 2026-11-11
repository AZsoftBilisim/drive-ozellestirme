///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

Function RegulatingConstants() Export
	
	Result = New Array();
	Result.Add("IndependentUsageOfAdditionalReportsAndDataProcessorsSaaS");
	Result.Add("AdditionalReportAndDataProcessorFolderUsageSaaS");
	
	Return New FixedArray(Result);
	
EndFunction

Function AttributesToControl() Export
	
	Result = New Array();
	Result.Add("SafeMode");
	Result.Add("DataProcessorStorage");
	Result.Add("ObjectName");
	Result.Add("Version");
	Result.Add("Kind");
	Result.Add("DeletionMark");
	
	Return New FixedArray(Result);
	
EndFunction

Function ExtendedLockReasonsDetails() Export
	
	Reasons = Enums.ReasonsForDisablingAdditionalReportsAndDataProcessorsSaaS;
	
	Result = New Map();
	Result.Insert(Reasons.LockByServiceAdministrator, 
		NStr("vi = 'Việc sử dụng xử lý bổ sung bị cấm bởi quản trị viên dịch vụ.';
			|ru = 'Использование дополнительной обработки запрещено администратором сервиса.';
			|en = 'Usage of additional data processor is prohibited by the SaaS administrator.'; fa = 'Usage of additional data processor is prohibited by the SaaS administrator.';
			|it = 'L''utilizzo dell''elaborazione aggiuntiva è vietato da parte dell''amministratore del servizio.';
			|pl = 'Zastosowanie przetwarzania dodatkowego jest zabronione przez administratora serwisu.';
			|tr = 'Ek veri işlemcisinin kullanılması, servis yöneticisi tarafından yasaklandı.'"));
	Result.Insert(Reasons.LockByOwner, 
		NStr("vi = 'Việc sử dụng xử lý bổ sung bị cấm bởi chủ sở hữu của chế biến.';
			|ru = 'Использование дополнительной обработки запрещено владельцем обработки.';
			|en = 'Usage of additional data processor is prohibited by the data processor owner.'; fa = 'Usage of additional data processor is prohibited by the data processor owner.';
			|it = 'L''utilizzo dell''elaborazione aggiuntiva è vietato da parte del proprietario dell''elaborazione.';
			|pl = 'Zastosowanie przetwarzania dodatkowego jest zabronione przez właściciela przetwarzania.';
			|tr = 'Ek veri işlemcisinin kullanılması, veri işlemcisinin sahibi tarafından yasaklandı.'"));
	Result.Insert(Reasons.ConfigurationVersionUpdate, 
		NStr("vi = 'Sử dụng xử lý bổ sung tạm thời không có sẵn. Hãy thử lại sau vài phút. Chúng tôi xin lỗi vì sự bất tiện này.';
			|ru = 'Использование дополнительной обработки временно недоступно. Попробуйте повторить через несколько минут. Приносим извинения на доставленные неудобства.';
			|en = 'Usage of additional data processor is temporarily unavailable. Try again in a few minutes. We apologize for the inconvenience.'; fa = 'Usage of additional data processor is temporarily unavailable. Try again in a few minutes. We apologize for the inconvenience.';
			|it = 'Uso dell''elaborazione aggiuntiva è temporaneamente non disponibile. Riprovate tra qualche minuto. Ci scusiamo per l''inconveniente.';
			|pl = 'Zastosowanie przetwarzania dodatkowego jest czasowo niedostępne. Spróbuj powtórzyć za kilka minut. Przepraszamy za przyczynione niedogodności.';
			|tr = 'Ek veri işlemcisi geçici olarak kullanılamıyor. Lütfen birkaç dakika içinde tekrar deneyin. Verdiğimiz rahatsızlıktan dolayı özür dileriz.'"));
	
	Return New FixedMap(Result);
	
EndFunction

#EndRegion