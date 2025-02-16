; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -attributor -attributor-manifest-internal -attributor-disable=false -attributor-max-iterations-verify -attributor-annotate-decl-cs -attributor-max-iterations=5 -S < %s | FileCheck %s --check-prefix=ATTRIBUTOR

target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

; Test cases specifically designed for "align" attribute.
; We use FIXME's to indicate problems and missing attributes.


; TEST 1
; ATTRIBUTOR: define align 8 i32* @test1(i32* nofree readnone returned align 8 "no-capture-maybe-returned" %0)
define i32* @test1(i32* align 8 %0) #0 {
  ret i32* %0
}

; TEST 2
; ATTRIBUTOR: define i32* @test2(i32* nofree readnone returned "no-capture-maybe-returned" %0)
define i32* @test2(i32* %0) #0 {
  ret i32* %0
}

; TEST 3
; ATTRIBUTOR: define align 4 i32* @test3(i32* nofree readnone align 8 "no-capture-maybe-returned" %0, i32* nofree readnone align 4 "no-capture-maybe-returned" %1, i1 %2)
define i32* @test3(i32* align 8 %0, i32* align 4 %1, i1 %2) #0 {
  %ret = select i1 %2, i32* %0, i32* %1
  ret i32* %ret
}

; TEST 4
; ATTRIBUTOR: define align 32 i32* @test4(i32* nofree readnone align 32 "no-capture-maybe-returned" %0, i32* nofree readnone align 32 "no-capture-maybe-returned" %1, i1 %2)
define i32* @test4(i32* align 32 %0, i32* align 32 %1, i1 %2) #0 {
  %ret = select i1 %2, i32* %0, i32* %1
  ret i32* %ret
}

; TEST 5
declare i32* @unknown()
declare align 8 i32* @align8()


; ATTRIBUTOR: define align 8 i32* @test5_1()
define i32* @test5_1() {
  %ret = tail call align 8 i32* @unknown()
  ret i32* %ret
}

; ATTRIBUTOR: define align 8 i32* @test5_2()
define i32* @test5_2() {
  %ret = tail call i32* @align8()
  ret i32* %ret
}

; TEST 6
; SCC
; ATTRIBUTOR: define noalias nonnull align 536870912 dereferenceable(4294967295) i32* @test6_1()
define i32* @test6_1() #0 {
  %ret = tail call i32* @test6_2()
  ret i32* %ret
}

; ATTRIBUTOR: define noalias nonnull align 536870912 dereferenceable(4294967295) i32* @test6_2()
define i32* @test6_2() #0 {
  %ret = tail call i32* @test6_1()
  ret i32* %ret
}


; char a1 __attribute__((aligned(8)));
; char a2 __attribute__((aligned(16)));
;
; char* f1(char* a ){
;     return a?a:f2(&a1);
; }
; char* f2(char* a){
;     return a?f1(a):f3(&a2);
; }
;
; char* f3(char* a){
;     return a?&a1: f1(&a2);
; }

@a1 = common global i8 0, align 8
@a2 = common global i8 0, align 16

; Function Attrs: nounwind readnone ssp uwtable
define internal i8* @f1(i8* readnone %0) local_unnamed_addr #0 {
  %2 = icmp eq i8* %0, null
  br i1 %2, label %3, label %5

; <label>:3:                                      ; preds = %1
  %4 = tail call i8* @f2(i8* nonnull @a1)
  %l = load i8, i8* %4
  br label %5

; <label>:5:                                      ; preds = %1, %3
  %6 = phi i8* [ %4, %3 ], [ %0, %1 ]
  ret i8* %6
}

; Function Attrs: nounwind readnone ssp uwtable
define internal i8* @f2(i8* readnone %0) local_unnamed_addr #0 {
  %2 = icmp eq i8* %0, null
  br i1 %2, label %5, label %3

; <label>:3:                                      ; preds = %1

  %4 = tail call i8* @f1(i8* nonnull %0)
  br label %7

; <label>:5:                                      ; preds = %1
  %6 = tail call i8* @f3(i8* nonnull @a2)
  br label %7

; <label>:7:                                      ; preds = %5, %3
  %8 = phi i8* [ %4, %3 ], [ %6, %5 ]
  ret i8* %8
}

; Function Attrs: nounwind readnone ssp uwtable
define internal i8* @f3(i8* readnone %0) local_unnamed_addr #0 {
  %2 = icmp eq i8* %0, null
  br i1 %2, label %3, label %5

; <label>:3:                                      ; preds = %1
  %4 = tail call i8* @f1(i8* nonnull @a2)
  br label %5

; <label>:5:                                      ; preds = %1, %3
  %6 = phi i8* [ %4, %3 ], [ @a1, %1 ]
  ret i8* %6
}

; TEST 7
; Better than IR information
define align 4 i32* @test7(i32* align 32 %p) #0 {
; ATTRIBUTOR-LABEL: define {{[^@]+}}@test7
; ATTRIBUTOR-SAME: (i32* nofree readnone returned align 32 "no-capture-maybe-returned" [[P:%.*]])
; ATTRIBUTOR-NEXT:    ret i32* [[P:%.*]]
;
  tail call i8* @f1(i8* align 8 dereferenceable(1) @a1)
  ret i32* %p
}

; TEST 7b
; Function Attrs: nounwind readnone ssp uwtable
define internal i8* @f1b(i8* readnone %0) local_unnamed_addr #0 {
;
; ATTRIBUTOR-LABEL: define {{[^@]+}}@f1b
; ATTRIBUTOR-SAME: (i8* nofree nonnull readnone align 8 dereferenceable(1) "no-capture-maybe-returned" [[TMP0:%.*]]) local_unnamed_addr
; ATTRIBUTOR-NEXT:    [[TMP2:%.*]] = icmp eq i8* [[TMP0:%.*]], null
; ATTRIBUTOR-NEXT:    br i1 [[TMP2]], label [[TMP3:%.*]], label [[TMP5:%.*]]
; ATTRIBUTOR:       3:
; ATTRIBUTOR-NEXT:    [[TMP4:%.*]] = tail call align 8 i8* @f2b(i8* nofree nonnull align 8 dereferenceable(1) @a1)
; ATTRIBUTOR-NEXT:    [[L:%.*]] = load i8, i8* [[TMP4]], align 8
; ATTRIBUTOR-NEXT:    store i8 [[L]], i8* @a1, align 8
; ATTRIBUTOR-NEXT:    br label [[TMP5]]
; ATTRIBUTOR:       5:
; ATTRIBUTOR-NEXT:    [[TMP6:%.*]] = phi i8* [ [[TMP4]], [[TMP3]] ], [ [[TMP0]], [[TMP1:%.*]] ]
; ATTRIBUTOR-NEXT:    ret i8* [[TMP6]]
;
  %2 = icmp eq i8* %0, null
  br i1 %2, label %3, label %5

; <label>:3:                                      ; preds = %1
  %4 = tail call i8* @f2b(i8* nonnull @a1)
  %l = load i8, i8* %4
  store i8 %l, i8* @a1
  br label %5

; <label>:5:                                      ; preds = %1, %3
  %6 = phi i8* [ %4, %3 ], [ %0, %1 ]
  ret i8* %6
}

; Function Attrs: nounwind readnone ssp uwtable
define internal i8* @f2b(i8* readnone %0) local_unnamed_addr #0 {
;
; ATTRIBUTOR-LABEL: define {{[^@]+}}@f2b
; ATTRIBUTOR-SAME: (i8* nofree nonnull readnone align 8 dereferenceable(1) "no-capture-maybe-returned" [[TMP0:%.*]]) local_unnamed_addr
; ATTRIBUTOR-NEXT:    [[TMP2:%.*]] = icmp eq i8* @a1, null
; ATTRIBUTOR-NEXT:    br i1 [[TMP2]], label [[TMP5:%.*]], label [[TMP3:%.*]]
; ATTRIBUTOR:       3:
; ATTRIBUTOR-NEXT:    [[TMP4:%.*]] = tail call i8* @f1b(i8* nofree nonnull align 8 dereferenceable(1) "no-capture-maybe-returned" @a1)
; ATTRIBUTOR-NEXT:    br label [[TMP7:%.*]]
; ATTRIBUTOR:       5:
; ATTRIBUTOR-NEXT:    [[TMP6:%.*]] = tail call i8* @f3b(i8* nofree nonnull align 16 dereferenceable(1) @a2)
; ATTRIBUTOR-NEXT:    br label [[TMP7]]
; ATTRIBUTOR:       7:
; ATTRIBUTOR-NEXT:    [[TMP8:%.*]] = phi i8* [ [[TMP4]], [[TMP3]] ], [ [[TMP6]], [[TMP5]] ]
; ATTRIBUTOR-NEXT:    ret i8* [[TMP8]]
;
  %2 = icmp eq i8* %0, null
  br i1 %2, label %5, label %3

; <label>:3:                                      ; preds = %1

  %4 = tail call i8* @f1b(i8* nonnull %0)
  br label %7

; <label>:5:                                      ; preds = %1
  %6 = tail call i8* @f3b(i8* nonnull @a2)
  br label %7

; <label>:7:                                      ; preds = %5, %3
  %8 = phi i8* [ %4, %3 ], [ %6, %5 ]
  ret i8* %8
}

; Function Attrs: nounwind readnone ssp uwtable
define internal i8* @f3b(i8* readnone %0) local_unnamed_addr #0 {
;
; ATTRIBUTOR-LABEL: define {{[^@]+}}@f3b
; ATTRIBUTOR-SAME: (i8* nocapture nofree nonnull readnone align 16 dereferenceable(1) [[TMP0:%.*]]) local_unnamed_addr
; ATTRIBUTOR-NEXT:    [[TMP2:%.*]] = icmp eq i8* @a2, null
; ATTRIBUTOR-NEXT:    br i1 [[TMP2]], label [[TMP3:%.*]], label [[TMP5:%.*]]
; ATTRIBUTOR:       3:
; ATTRIBUTOR-NEXT:    [[TMP4:%.*]] = tail call i8* @f1b(i8* nofree nonnull align 16 dereferenceable(1) @a2)
; ATTRIBUTOR-NEXT:    br label [[TMP5]]
; ATTRIBUTOR:       5:
; ATTRIBUTOR-NEXT:    [[TMP6:%.*]] = phi i8* [ [[TMP4]], [[TMP3]] ], [ @a1, [[TMP1:%.*]] ]
; ATTRIBUTOR-NEXT:    ret i8* [[TMP6]]
;
  %2 = icmp eq i8* %0, null
  br i1 %2, label %3, label %5

; <label>:3:                                      ; preds = %1
  %4 = tail call i8* @f1b(i8* nonnull @a2)
  br label %5

; <label>:5:                                      ; preds = %1, %3
  %6 = phi i8* [ %4, %3 ], [ @a1, %1 ]
  ret i8* %6
}

define align 4 i32* @test7b(i32* align 32 %p) #0 {
; ATTRIBUTOR-LABEL: define {{[^@]+}}@test7b
; ATTRIBUTOR-SAME: (i32* nofree readnone returned align 32 "no-capture-maybe-returned" [[P:%.*]])
; ATTRIBUTOR-NEXT:    [[TMP1:%.*]] = tail call i8* @f1b(i8* nofree nonnull align 8 dereferenceable(1) @a1)
; ATTRIBUTOR-NEXT:    ret i32* [[P:%.*]]
;
  tail call i8* @f1b(i8* align 8 dereferenceable(1) @a1)
  ret i32* %p
}


; TEST 8
define void @test8_helper() {
  %ptr0 = tail call i32* @unknown()
  %ptr1 = tail call align 4 i32* @unknown()
  %ptr2 = tail call align 8 i32* @unknown()

  tail call void @test8(i32* %ptr1, i32* %ptr1, i32* %ptr0)
; ATTRIBUTOR: tail call void @test8(i32* align 4 %ptr1, i32* align 4 %ptr1, i32* %ptr0)
  tail call void @test8(i32* %ptr2, i32* %ptr1, i32* %ptr1)
; ATTRIBUTOR: tail call void @test8(i32* align 8 %ptr2, i32* align 4 %ptr1, i32* align 4 %ptr1)
  tail call void @test8(i32* %ptr2, i32* %ptr1, i32* %ptr1)
; ATTRIBUTOR: tail call void @test8(i32* align 8 %ptr2, i32* align 4 %ptr1, i32* align 4 %ptr1)
  ret void
}

declare void @user_i32_ptr(i32*) readnone nounwind
define internal void @test8(i32* %a, i32* %b, i32* %c) {
; ATTRIBUTOR: define internal void @test8(i32* nocapture readnone align 4 %a, i32* nocapture readnone align 4 %b, i32* nocapture readnone %c)
  call void @user_i32_ptr(i32* %a)
  call void @user_i32_ptr(i32* %b)
  call void @user_i32_ptr(i32* %c)
  ret void
}

declare void @test9_helper(i32* %A)
define void @test9_traversal(i1 %c, i32* align 4 %B, i32* align 8 %C) {
  %sel = select i1 %c, i32* %B, i32* %C
  call void @test9_helper(i32* %sel)
  ret void
}

; FIXME: This will work with an upcoming patch (D66618 or similar)
;             define align 32 i32* @test10a(i32* align 32 "no-capture-maybe-returned" %p)
; ATTRIBUTOR: define i32* @test10a(i32* nofree nonnull align 32 dereferenceable(4) "no-capture-maybe-returned" %p)
define i32* @test10a(i32* align 32 %p) {
; ATTRIBUTOR: %l = load i32, i32* %p, align 32
  %l = load i32, i32* %p
  %c = icmp eq i32 %l, 0
  br i1 %c, label %t, label %f
t:
  %r = call i32* @test10a(i32* %p)
; FIXME: This will work with an upcoming patch (D66618 or similar)
;             store i32 1, i32* %r, align 32
; ATTRIBUTOR: store i32 1, i32* %r
  store i32 1, i32* %r
  %g0 = getelementptr i32, i32* %p, i32 8
  br label %e
f:
  %g1 = getelementptr i32, i32* %p, i32 8
; FIXME: This will work with an upcoming patch (D66618 or similar)
;             store i32 -1, i32* %g1, align 32
; ATTRIBUTOR: store i32 -1, i32* %g1
  store i32 -1, i32* %g1
  br label %e
e:
  %phi = phi i32* [%g0, %t], [%g1, %f]
  ret i32* %phi
}

; FIXME: This will work with an upcoming patch (D66618 or similar)
;             define align 32 i32* @test10b(i32* align 32 "no-capture-maybe-returned" %p)
; ATTRIBUTOR: define i32* @test10b(i32* nofree nonnull align 32 dereferenceable(4) "no-capture-maybe-returned" %p)
define i32* @test10b(i32* align 32 %p) {
; ATTRIBUTOR: %l = load i32, i32* %p, align 32
  %l = load i32, i32* %p
  %c = icmp eq i32 %l, 0
  br i1 %c, label %t, label %f
t:
  %r = call i32* @test10b(i32* %p)
; FIXME: This will work with an upcoming patch (D66618 or similar)
;             store i32 1, i32* %r, align 32
; ATTRIBUTOR: store i32 1, i32* %r
  store i32 1, i32* %r
  %g0 = getelementptr i32, i32* %p, i32 8
  br label %e
f:
  %g1 = getelementptr i32, i32* %p, i32 -8
; FIXME: This will work with an upcoming patch (D66618 or similar)
;             store i32 -1, i32* %g1, align 32
; ATTRIBUTOR: store i32 -1, i32* %g1
  store i32 -1, i32* %g1
  br label %e
e:
  %phi = phi i32* [%g0, %t], [%g1, %f]
  ret i32* %phi
}


; ATTRIBUTOR: define i64 @test11(i32* nocapture nofree nonnull readonly align 8 dereferenceable(8) %p)
define i64 @test11(i32* %p) {
  %p-cast = bitcast i32* %p to i64*
  %ret = load i64, i64* %p-cast, align 8
  ret i64 %ret
}

; TEST 12
; Test for deduction using must-be-executed-context and GEP instruction 

; FXIME: %p should have nonnull
; ATTRIBUTOR: define i64 @test12-1(i32* nocapture nofree readonly align 16 %p)
define i64 @test12-1(i32* align 4 %p) {
  %p-cast = bitcast i32* %p to i64*
  %arrayidx0 = getelementptr i64, i64* %p-cast, i64 1
  %arrayidx1 = getelementptr i64, i64* %arrayidx0, i64 3
  %ret = load i64, i64* %arrayidx1, align 16
  ret i64 %ret
}

; FXIME: %p should have nonnull
; ATTRIBUTOR: define i64 @test12-2(i32* nocapture nofree readonly align 16 %p)
define i64 @test12-2(i32* align 4 %p) {
  %p-cast = bitcast i32* %p to i64*
  %arrayidx0 = getelementptr i64, i64* %p-cast, i64 0
  %ret = load i64, i64* %arrayidx0, align 16
  ret i64 %ret
}

; FXIME: %p should have nonnull
; ATTRIBUTOR: define void @test12-3(i32* nocapture nofree writeonly align 16 %p)
define void @test12-3(i32* align 4 %p) {
  %p-cast = bitcast i32* %p to i64*
  %arrayidx0 = getelementptr i64, i64* %p-cast, i64 1
  %arrayidx1 = getelementptr i64, i64* %arrayidx0, i64 3
  store i64 0, i64* %arrayidx1, align 16
  ret void 
}

; FXIME: %p should have nonnull
; ATTRIBUTOR: define void @test12-4(i32* nocapture nofree writeonly align 16 %p)
define void @test12-4(i32* align 4 %p) {
  %p-cast = bitcast i32* %p to i64*
  %arrayidx0 = getelementptr i64, i64* %p-cast, i64 0
  store i64 0, i64* %arrayidx0, align 16
  ret void 
}

declare void @use(i64*) willreturn nounwind

; ATTRIBUTOR: define void @test12-5(i32* align 16 %p)
define void @test12-5(i32* align 4 %p) {
  %p-cast = bitcast i32* %p to i64*
  %arrayidx0 = getelementptr i64, i64* %p-cast, i64 1
  %arrayidx1 = getelementptr i64, i64* %arrayidx0, i64 3
  tail call void @use(i64* align 16 %arrayidx1)
  ret void 
}

; ATTRIBUTOR: define void @test12-6(i32* align 16 %p)
define void @test12-6(i32* align 4 %p) {
  %p-cast = bitcast i32* %p to i64*
  %arrayidx0 = getelementptr i64, i64* %p-cast, i64 0
  tail call void @use(i64* align 16 %arrayidx0)
  ret void 
}

attributes #0 = { nounwind uwtable noinline }
attributes #1 = { uwtable noinline }
