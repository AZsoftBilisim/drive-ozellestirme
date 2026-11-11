///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns the annual schedule for the event as of the specified date.
//
// Parameters:
//  EventDate - Date - custom date.
//
// Returns:
//  JobSchedule - schedule.
//
Function AnnualSchedule(EventDate) Export
	Months = New Array;
	Months.Add(Month(EventDate));
	DayInMonth = Day(EventDate);
	
	Schedule = New JobSchedule;
	Schedule.DaysRepeatPeriod = 1;
	Schedule.WeeksPeriod = 1;
	Schedule.Months = Months;
	Schedule.DayInMonth = DayInMonth;
	Schedule.BeginTime = '000101010000' + (EventDate - BegOfDay(EventDate));
	
	Return Schedule;
EndFunction

#EndRegion

#Region Private

// Returns the reminder structure with filled values.
//
// Parameters:
//  DataToFill - Structure - values used to fill reminder parameters.
//  AllAttributes - Boolean - if true, the function also returns attributes related to
//                          reminder time settings.
//
Function ReminderDetails(DataToFill = Undefined, AllAttributes = False) Export
	
	Result = New Structure("User,EventTime,Source,ReminderTime,LongDesc,Id,URL");
	
	If AllAttributes Then 
		Result.Insert("ReminderTimeSettingMethod");
		Result.Insert("ReminderInterval", 0);
		Result.Insert("SourceAttributeName");
		Result.Insert("Schedule");
		Result.Insert("PictureIndex", 2);
		Result.Insert("RepeatAnnually", False);
	EndIf;
	
	If DataToFill <> Undefined Then
		FillPropertyValues(Result, DataToFill);
	EndIf;
	
	If AllAttributes 
		And Result.ReminderTimeSettingMethod <> Undefined
		And Result.ReminderTimeSettingMethod <> PredefinedValue("Enum.ReminderTimeSettingMethods.RelativeToSubjectTime") Then
		Result.SourceAttributeName = "";
	EndIf;
	
	Return Result;
EndFunction

Function ServerNotificationName() Export
	
	Return "StandardSubsystems.UserReminders";
	
EndFunction

// Returns a text presentation of a time interval specified in seconds.
//
// Parameters:
//
//  Time - Number - Time interval in seconds.
//
//  FullPresentation	- Boolean - The brief or full presentation of a time interval.
//		For example, if the interval is 1,000,000 seconds::
//		1. Its full presentation is "11 days 13 hours 46 minutes 40 seconds".
//		2. Its brief presentation is "11 days 13 hours".
//  
//  OutputSeconds - Boolean - False if seconds are not required.
//  
// Returns:
//   String - A time interval presentation.
//
Function TimePresentation(Val Time, FullPresentation = True, OutputSeconds = True) Export
	Result = "";
	
	// Presentation of time measurement units in Accusative for quantities: 1, 2-4, and 5-20.
	WeeksPresentation = NStr("vi = ';%1 tuần;;%1 tuần;%1 tuần;%1 tuần';
							|ru = ';%1 неделю;;%1 недели;%1 недель;%1 недели';
							|en = ';%1 week;;;;%1 weeks'; fa = ';%1 week;;;;%1 weeks';
							|it = ';%1 settimana;;%1 settimane; %1 settimane:%1 settimane';
							|pl = ';%1 tydzień;;%1 tygodnie;%1 tygodnie;%1 tygodnia';
							|tr = ';%1 hafta;;%1 hafta;%1 hafta;%1 hafta'");
	DaysPresentation   = NStr("vi = ';%1 ngày;;%1 ngày;%1 ngày;%1 ngày';
								|ru = ';%1 день;;%1 дня;%1 дней;%1 дня';
								|en = ';%1 day;;;;%1 days'; fa = ';%1 day;;;;%1 days';
								|it = ';%1 giorno;;%1 giorno;%1 giorni;%1 giorno';
								|pl = ';%1 dzień;;%1 dnia;%1 dni;%1 dnia';
								|tr = ';%1 gün;;%1 gün;%1 gün;%1 gün'");
	HoursPresentation  = NStr("vi = ';%1 giờ;;%1 giờ;%1 giờ;%1 giờ';
								|ru = ';%1 час;;%1 часа;%1 часов;%1 часа';
								|en = ';%1 hour;;;;%1 hours'; fa = ';%1 hour;;;;%1 hours';
								|it = ';%1 ora;;%1 ora;%1 ore;%1 ora';
								|pl = ';%1 godzina;;%1 godziny;%1 godzin;%1 godzin';
								|tr = ';%1 saat;;%1 saat;%1 saat;%1 saat'");
	MinutesPresentation  = NStr("vi = ';%1 phút;;%1 phút;%1 phút;%1 phút';
								|ru = ';%1 минуту;;%1 минуты;%1 минут;%1 минуты';
								|en = ';%1 minute;;;;%1 minutes'; fa = ';%1 minute;;;;%1 minutes';
								|it = ';%1 minuto;;%1 minuto;%1 minuti;%1 minuti';
								|pl = ';%1 minutę;;%1 minuty;%1 minut;%1 minuty';
								|tr = ';%1 dakika;;%1 dakika;%1 dakika;%1 dakika'");
	SecondsPresentation = NStr("vi = ';%1 giây;;%1 giây;%1 giây;%1 giây';
								|ru = ';%1 секунду;;%1 секунды;%1 секунд;%1 секунды';
								|en = ';%1 second;;;;%1 seconds'; fa = ';%1 second;;;;%1 seconds';
								|it = ';%1 secondo;;%1 secondo;%1 secondi;%1 secondi';
								|pl = ';%1 sekundę;%1 sekundy;%1 sekund;%1 sekundy';
								|tr = ';%1 saniye;;%1 saniye;%1 saniye;%1 saniye'");
	
	Time = Number(Time);
	
	If Time < 0 Then
		Time = -Time;
	EndIf;
	
	WeeksCount = Int(Time / 60/60/24/7);
	DaysCount   = Int(Time / 60/60/24);
	HoursCount  = Int(Time / 60/60);
	MinutesCount  = Int(Time / 60);
	SecondsCount = Int(Time);
	
	SecondsCount = SecondsCount - MinutesCount * 60;
	MinutesCount  = MinutesCount - HoursCount * 60;
	HoursCount  = HoursCount - DaysCount * 24;
	DaysCount   = DaysCount - WeeksCount * 7;
	
	If Not OutputSeconds Then
		SecondsCount = 0;
	EndIf;
	
	If WeeksCount > 0 And DaysCount+HoursCount+MinutesCount+SecondsCount=0 Then
		Result = StringFunctionsClientServer.StringWithNumberForAnyLanguage(WeeksPresentation, WeeksCount);
	Else
		DaysCount = DaysCount + WeeksCount * 7;
		
		Counter = 0;
		If DaysCount > 0 Then
			Result = Result + StringFunctionsClientServer.StringWithNumberForAnyLanguage(DaysPresentation, DaysCount) + " ";
			Counter = Counter + 1;
		EndIf;
		
		If HoursCount > 0 Then
			Result = Result + StringFunctionsClientServer.StringWithNumberForAnyLanguage(HoursPresentation, HoursCount) + " ";
			Counter = Counter + 1;
		EndIf;
		
		If (FullPresentation Or Counter < 2) And MinutesCount > 0 Or Time = 0 And Not OutputSeconds Then
			Result = Result + StringFunctionsClientServer.StringWithNumberForAnyLanguage(MinutesPresentation, MinutesCount) + " ";
			Counter = Counter + 1;
		EndIf;
		
		If OutputSeconds And (FullPresentation Or Counter < 2) And (SecondsCount > 0 Or WeeksCount+DaysCount+HoursCount+MinutesCount = 0) Then
			Result = Result + StringFunctionsClientServer.StringWithNumberForAnyLanguage(SecondsPresentation, SecondsCount);
		EndIf;
		
	EndIf;
	
	Return TrimR(Result);
	
EndFunction

Function FieldNameRemindAboutEvent() Export
	
	Return "RemindAboutEvent";
	
EndFunction

Function FieldNameReminderTimeInterval() Export
	Return "ReminderInterval";
EndFunction

Function NameOfReminderSettingsField() Export
	Return "SettingsOfReminder";
EndFunction

Function ReminderSettingsInForm(Form) Export
	
	AttributesValues = New Structure(NameOfReminderSettingsField());
	FillPropertyValues(AttributesValues, Form);
	Return AttributesValues[NameOfReminderSettingsField()];
	
EndFunction

// Gets a time interval in seconds from text details.
//
// Parameters:
//  StringWithTime - String - text details of time, where numbers are written in digits
//								and units of measure are written as a string. 
//
// Returns:
//  Number - Time interval in seconds.
// 
Function TimeIntervalFromString(Val StringWithTime) Export
	
	If IsBlankString(StringWithTime) Then
		Return 0;
	EndIf;
	
	StringWithTime = Lower(StringWithTime);
	StringWithTime = StrReplace(StringWithTime, Chars.NBSp," ");
	StringWithTime = StrReplace(StringWithTime, ".",",");
	StringWithTime = StrReplace(StringWithTime, "+","");
	
	SubstringWithDigits = "";
	SubstringWithLetters = "";
	
	PreviousCharIsDigit = False;
	HasFractionalPart = False;
	
	Result = 0;
	For Position = 1 To StrLen(StringWithTime) Do
		CurrentCharCode = CharCode(StringWithTime,Position);
		Char = Mid(StringWithTime,Position,1);
		If (CurrentCharCode >= CharCode("0") And CurrentCharCode <= CharCode("9"))
			Or (Char="," And PreviousCharIsDigit And Not HasFractionalPart) Then
			If Not IsBlankString(SubstringWithLetters) Then
				SubstringWithDigits = StrReplace(SubstringWithDigits,",",".");
				Result = Result + ?(IsBlankString(SubstringWithDigits), 1, Number(SubstringWithDigits))
					* ReplaceUnitOfMeasureByMultiplier(SubstringWithLetters);
					
				SubstringWithDigits = "";
				SubstringWithLetters = "";
				
				PreviousCharIsDigit = False;
				HasFractionalPart = False;
			EndIf;
			
			SubstringWithDigits = SubstringWithDigits + Mid(StringWithTime,Position,1);
			
			PreviousCharIsDigit = True;
			If Char = "," Then
				HasFractionalPart = True;
			EndIf;
		Else
			If Char = " " And ReplaceUnitOfMeasureByMultiplier(SubstringWithLetters) = "0" Then
				SubstringWithLetters = "";
			EndIf;
			
			SubstringWithLetters = SubstringWithLetters + Mid(StringWithTime,Position,1);
			PreviousCharIsDigit = False;
		EndIf;
	EndDo;
	
	If Not IsBlankString(SubstringWithLetters) Then
		SubstringWithDigits = StrReplace(SubstringWithDigits,",",".");
		Result = Result + ?(IsBlankString(SubstringWithDigits), 1, Number(SubstringWithDigits))
			* ReplaceUnitOfMeasureByMultiplier(SubstringWithLetters);
	EndIf;
	
	Return Result;
	
EndFunction

// Analyzes the word for compliance with the time unit of measure and if it complies,
// the function returns the number of seconds contained in the time unit of measure.
//
// Parameters:
//  Unit - String - Word being analyzed.
//
// Returns:
//  Number - The number of seconds in the unit. If the unit is unidentified or empty, returns "0".
//
Function ReplaceUnitOfMeasureByMultiplier(Val Unit)
	
	Result = 0;
	Unit = Lower(Unit);
	
	AllowedChars = NStr("vi = 'абвгдеёжзийклмнопрстуфхцчшщъыьэюя';
						|ru = 'абвгдеёжзийклмнопрстуфхцчшщъыьэюя';
						|en = 'abcdefghijklmnopqrstuvwxyz'; fa = 'abcdefghijklmnopqrstuvwxyz';
						|it = 'абвгдеёжзийклмнопрстуфхцчшщъыьэюя';
						|pl = 'abcdefghijklmnopqrstuvwxyz';
						|tr = 'abcdefghıijklmnoöprsştuüvyz'"); // APK:163; APK:1036 (see 456:1.1) characters that the user can enter.
	ProhibitedChars = StrConcat(StrSplit(Unit, AllowedChars, False), "");
	If ProhibitedChars <> "" Then
		Unit = StrConcat(StrSplit(Unit, ProhibitedChars, False), "");
	EndIf;
	
	WordFormsForWeek = StrSplit(NStr("vi = 'tuần,t';
									|ru = 'нед,н';
									|en = 'wk,w,wee'; fa = 'wk,w,wee';
									|it = 'нед,н';
									|pl = 'wk,w,wee';
									|tr = 'haf,h'"), ",", False);
	WordFormsForDay = StrSplit(NStr("vi = 'ngày,ngày,ngày,ngày,ngày';
									|ru = 'ден,дне,дня,дн,д';
									|en = 'day,d'; fa = 'day,d';
									|it = 'ден,дне,дня,дн,д';
									|pl = 'day,d';
									|tr = 'gün,gün,gün,gün,g'"), ",", False);
	WordFormsForHour = StrSplit(NStr("vi = 'giờ, h';
									|ru = 'час,ч';
									|en = 'hrs,hr,h,hou'; fa = 'hrs,hr,h,hou';
									|it = 'час,ч';
									|pl = 'hrs,hr,h,hou';
									|tr = 'saa,s'"), ",", False);
	WordFormsForMinute = StrSplit(NStr("vi = 'phút,m';
										|ru = 'мин,м';
										|en = 'min,m'; fa = 'min,m';
										|it = 'мин,м';
										|pl = 'min,m';
										|tr = 'dak,d'"), ",", False);
	WordFormsForSecond = StrSplit(NStr("vi = 'giây,s';
										|ru = 'сек,с';
										|en = 'sec,s'; fa = 'sec,s';
										|it = 'сек,с';
										|pl = 'sec,s';
										|tr = 'san,s'"), ",", False);
	
	FirstThreeChars = Left(Unit,3);
	If WordFormsForWeek.Find(FirstThreeChars) <> Undefined Then
		Result = 60*60*24*7;
	ElsIf WordFormsForDay.Find(FirstThreeChars) <> Undefined Then
		Result = 60*60*24;
	ElsIf WordFormsForHour.Find(FirstThreeChars) <> Undefined Then
		Result = 60*60;
	ElsIf WordFormsForMinute.Find(FirstThreeChars) <> Undefined Then
		Result = 60;
	ElsIf WordFormsForSecond.Find(FirstThreeChars) <> Undefined Then
		Result = 1;
	EndIf;
	
	Return Format(Result,"NZ=0; NG=0");
	
EndFunction

Function EnumPresentationDoNotRemind() Export
	
	Return NStr("vi = 'không nhắc';
				|ru = 'не напоминать';
				|en = 'do not remind'; fa = 'do not remind';
				|it = 'не напоминать';
				|pl = 'do not remind';
				|tr = 'hatırlatma'");
	
EndFunction

Function EnumPresentationOnOccurrence() Export
	
	Return NStr("vi = 'khi bắt đầu';
				|ru = 'при наступлении';
				|en = 'on occurrence'; fa = 'on occurrence';
				|it = 'при наступлении';
				|pl = 'on occurrence';
				|tr = 'olması durumunda'");
	
EndFunction

Function EnumPresentationOnSchedule()
	
	Return NStr("vi = 'theo lịch biểu';
				|ru = 'по расписанию';
				|en = 'on schedule'; fa = 'on schedule';
				|it = 'по расписанию';
				|pl = 'on schedule';
				|tr = 'programa göre'");
	
EndFunction

// Parameters:
//  Reminder - See ReminderDetails
//
Function ReminderTimePresentation(Reminder) Export
	
	If Reminder.ReminderTimeSettingMethod = PredefinedValue("Enum.ReminderTimeSettingMethods.RelativeToSubjectTime") Then
		If Reminder.ReminderInterval = 0 Then
			Return EnumPresentationOnOccurrence();
		Else
			Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'trong %1';
					|ru = 'за %1';
					|en = '%1 before'; fa = '%1 before';
					|it = 'in %1';
					|pl = 'za %1';
					|tr = '%1 için'"), TimePresentation(Reminder.ReminderInterval));
		EndIf;
	ElsIf Reminder.ReminderTimeSettingMethod = PredefinedValue("Enum.ReminderTimeSettingMethods.AtSpecifiedTime")
		Or Reminder.ReminderTimeSettingMethod = PredefinedValue("Enum.ReminderTimeSettingMethods.RelativeToCurrentTime") Then
		Return StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1';
				|ru = '%1';
				|en = '%1'; fa = '%1';
				|it = '%1';
				|pl = '%1';
				|tr = '%1'"), Format(Reminder.ReminderTime, "DLF=DT;"));
	Else
		Return EnumPresentationOnSchedule();
	EndIf;
	
EndFunction

Function IsMessageURL(URL) Export
	Return StrStartsWith(URL, "e1ccs/data/msg?id=");
EndFunction

#EndRegion
