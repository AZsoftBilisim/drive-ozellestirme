
#Region Private

// The function checks whether the object is used in a long operation
// 
// Parameters:
//  Ref - AnyRef - The object of verification.
//  UUID - UUID - id of the form in which the check is being run.
//  FormStorageAddress_ - String - address of the storage where the verification result will be placed.
//  ThereAreRefs - Boolean - Flag indicating the presence of references to the object.
//  UseLocalValidationFunction - Boolean - Use the local verification function
// 
// Returns:
//  Structure - Check object usage:
//   * StorageAddress  - String     - the address of the temporary storage where the result of the task will be placed;
//   * JobID - UUID - unique ID of the running background task;
//   * JobCompleted - Boolean - True if the task was completed successfully during the function call.
Function CheckObjectUsage(Ref, UUID, FormStorageAddress_, ThereAreRefs, UseLocalValidationFunction = False) Export
	
	JobParameters = New Structure;
	JobParameters.Insert("Object", Ref);
	
	If UseLocalValidationFunction Then
		CheckProcedure = Common.BaseTypeNameByMetadataObject(Ref.Metadata())
		                  + "." +Ref.Metadata().Name
		                  + ".CheckObjectUsage";
	Else
		CheckProcedure = "TMCommonUse.CheckObjectUsage";
	EndIf;
	
	JobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Kiểm tra việc sử dụng đối tượng %1';
			|ru = 'Проверка использования объекта %1';
			|en = 'Checking usage of object %1'; fa = 'Checking usage of object %1';
			|it = 'Verifica dell''utilizzo dell''oggetto %1';
			|pl = 'Weryfikacja wykorzystania obiektu %1';
			|tr = '%1 nesnesinin kullanım kontrolü'"),
		Ref);

	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground = True;
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	
	Result = TimeConsumingOperations.ExecuteInBackground(
		CheckProcedure,
		JobParameters,
		ExecutionParameters);
	
	FormStorageAddress_ = Result.ResultAddress;
	
	If Result.Status = "Completed2" Then
		ThereAreRefs = GetFromTempStorage(FormStorageAddress_);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion
