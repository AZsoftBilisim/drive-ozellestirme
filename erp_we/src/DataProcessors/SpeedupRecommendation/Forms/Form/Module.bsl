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
	CommonParameters = Common.CommonCoreParameters();
	RecommendedSize = CommonParameters.RecommendedRAM;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Cancel = True;
	
	SystemInfo = New SystemInfo;
	AvailableMemorySize = Round(SystemInfo.RAM / 1024, 1);
	
	If AvailableMemorySize >= RecommendedSize Then
		Return;
	EndIf;
	
	MessageText = NStr("vi = 'Máy tính có %1 Gb Ram. 
		|Để ứng dụng chạy nhanh hơn, 
		|bạn nên tăng dung lượng bộ nhớ lên %2 Gb.';
		|ru = 'На компьютере установлено %1 Гб оперативной памяти.
		|Для того чтобы приложение работало быстрее, 
		|рекомендуется увеличить объем памяти до %2 Гб.';
		|en = 'Your computer has %1 GB of RAM.
		|
		|Recommended RAM size is %2 GB.'; fa = 'Your computer has %1 GB of RAM.
		|
		|Recommended RAM size is %2 GB.';
		|it = 'На компьютере установлено %1 Гб оперативной памяти.
		|Для того чтобы приложение работало быстрее, 
		|рекомендуется увеличить объем памяти до %2 Гб.';
		|pl = 'Your computer has %1 GB of RAM.
		|
		|Recommended RAM size is %2 GB.';
		|tr = 'Bilgisayarda %1GB RAM yüklü. %2uygulamanın daha hızlı çalışmasını sağlamak için 
		|bellek miktarını 
		|GB''ye yükseltmeniz önerilir.'");
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, AvailableMemorySize, RecommendedSize);
	
	MessageTitle = NStr("vi = 'Khuyến cáo nhằm tăng tốc độ làm việc';
						|ru = 'Рекомендация по повышению скорости работы';
						|en = 'Speedup recommendation'; fa = 'توصیه افزایش سرعت';
						|it = 'Suggerimenti per aumentare la velocità del lavoro';
						|pl = 'Zalecenie odnośnie zwiększenia szybkości pracy';
						|tr = 'Çalışma hızının arttırılması ile ilgili öneri'");
	
	QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
	QuestionParameters.Title = MessageTitle;
	QuestionParameters.Picture = PictureLib.DialogExclamation;
	QuestionParameters.Insert("CheckBoxText", NStr("vi = 'Không hiển thị trong vòng hai tháng';
													|ru = 'Не показывать в течение двух месяцев';
													|en = 'Remind in two months'; fa = 'Remind in two months';
													|it = 'Non mostrare per due mesi';
													|pl = 'Nie pokazuj w ciągu dwuch miesięcy';
													|tr = 'İki ay boyunca görüntülenmesin'"));
	
	Buttons = New ValueList;
	Buttons.Add("ContinueWork", NStr("vi = 'Tiếp tục công việc';
									|ru = 'Продолжить работу';
									|en = 'Continue'; fa = 'ادامه';
									|it = 'Continuare il lavoro';
									|pl = 'Kontynuuj pracę';
									|tr = 'Devam et'"));
	
	CallbackDescription = New CallbackDescription("AfterShowRecommendation", ThisObject);
	StandardSubsystemsClient.ShowQuestionToUser(CallbackDescription, MessageText, Buttons, QuestionParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterShowRecommendation(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	RAMRecommendation = New Structure;
	RAMRecommendation.Insert("Show", Not Result.NeverAskAgain);
	RAMRecommendation.Insert("PreviousShowDate", CommonClient.SessionDate());
	
	CommonClient.CommonSettingsStorageSave("UserCommonSettings",
		"RAMRecommendation", RAMRecommendation);
EndProcedure

#EndRegion
