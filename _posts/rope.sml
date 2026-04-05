structure IntervalRope = 
struct
  datatype interval_rope = 
    Concat of interval_rope * int * interval_rope
  | Leaf of {startIdx: int, endIdx : int}

  type t = interval_rope option

  fun uHasIntervalAtIndex (index, rope) =
    case rope of
      Leaf {startIdx, endIdx} =>
        startIdx <= index andalso endIdx >= index
    | Concat (left, weight, right) =>
        if index <= weight then
          uHasIntervalAtIndex (index, left)
        else
          uHasIntervalAtIndex (index - weight, right)

  fun hasIntervalAtIndex (index, rope) =
    case rope of
      SOME rope => uHasIntervalAtIndex (index, rope)
    | NONE => false

  fun uLargestIdx (rope, acc) =
  case rope of
    Leaf {startIdx, endIdx} => endIdx + acc
  | Concat (left, weight, right) =>
      uLargestIdx (right, acc + weight)

  fun largestIdx rope =
    case rope of
      SOME rope => uLargestIdx (rope, 0)
    | NONE => 0

  fun smallestIdx rope =
    case rope of
      Leaf {startIdx, endIdx} => startIdx
    | Concat (left, weight, right) => smallestIdx left

  fun concatenate (left, right) =
    Concat (left, uLargestIdx (left, 0), right)

  fun splitKeepingStart (index, rope) =
    case rope of
      Leaf {startIdx, endIdx} =>
        if index > endIdx then
          SOME rope
        else
          NONE
    | Concat (left, weight, right) =>
        if index <= weight then
          splitKeepingStart (index, left)
        else
          let
            val result = splitKeepingStart (index - weight, right)
          in
            case result of
              SOME newRight => SOME (Concat (left, weight, newRight))
            | NONE => SOME left
          end

  fun splitKeepingEnd (index, rope) =
    case rope of
      Leaf {startIdx, endIdx} =>
        if index < startIdx then
          SOME rope
        else
          NONE
    | Concat  (left, weight, right) =>
        if index <= weight then
          case splitKeepingEnd (index, left) of
            SOME newLeft => SOME (Concat (newLeft, uLargestIdx (newLeft, 0), right))
          | NONE => SOME right
        else
          splitKeepingEnd (index - weight, right)

  fun decrement (decrementBy, rope) =
    case rope of
      Leaf {startIdx, endIdx} =>
        Leaf {
          startIdx = startIdx - decrementBy, 
          endIdx = endIdx - decrementBy
        }
    | Concat (left, weight, right) =>
        let
          val newLeft = decrement (decrementBy, left)
          val newWeight = weight - decrementBy
        in
          Concat (newLeft, newWeight, right)
        end

  fun increment (incrementBy, rope) =
    case rope of
      Leaf {startIdx, endIdx} =>
        Leaf {
          startIdx = startIdx + incrementBy, 
          endIdx = endIdx + incrementBy
        }
    | Concat (left, weight, right) =>
        let
          val newLeft = increment (incrementBy, left)
          val newWeight = weight + incrementBy
        in
          Concat (newLeft, newWeight, right)
        end

  fun incrementAt (idx, incrementBy, rope) =
    case rope of
      SOME rope =>
        let
          val left = splitKeepingStart (idx, rope)
          val right = splitKeepingEnd (idx, rope)
        in
          case (left, right) of
            (SOME left, SOME right) =>
             let
               val newRight = increment (incrementBy, right)
             in
               SOME (concatenate (left, newRight))
             end
          | (SOME left, NONE) =>
              (* nothing to increment since no intervals after index *) 
              SOME left
          | (NONE, SOME right) =>
              (* just incremet right and return without concatenating, since there is no left *) 
              SOME (increment (incrementBy, right))
          | (NONE, NONE) =>
              (* nothing remains after splitting, so return nothing *)
              NONE
        end
    | NONE => NONE


  fun smallestInterval (rope, acc) =
    case rope of
      Leaf {startIdx, endIdx} => 
        {startIdx = startIdx + acc, endIdx = endIdx + acc}
    | Concat (left, weight, right) => smallestInterval (left, acc)

  fun helpNextMatch (index, rope, acc) =
    case rope of
      Leaf {startIdx, endIdx} =>
        if index < startIdx then
          SOME {startIdx = startIdx + acc, endIdx = endIdx + acc}
        else
          NONE
    | Concat (left, weight, right) =>
        if index < weight then
          case helpNextMatch (index, left, acc) of
            SOME interval => SOME interval
          | NONE => SOME (smallestInterval (right, acc + weight))
        else
          helpNextMatch (index - weight, right, acc + weight)

  fun nextMatch (index, rope) = helpNextMatch (index, rope, 0)

  fun largestInterval (index, rope, acc) = 
    case rope of
      Leaf {startIdx, endIdx} => 
        SOME {startIdx = startIdx + acc, endIdx = endIdx + acc}
    | Concat (left, weight, right) => largestInterval (index, rope, acc)

  fun helpPrevMatch (index, rope, acc) =
    case rope of
      Leaf {startIdx, endIdx} => 
        SOME {startIdx = startIdx + acc, endIdx = endIdx + acc}
    | Concat (left, weight, right) =>
        if index < weight then
          helpPrevMatch (index, left, acc)
        else
          case helpPrevMatch (index, right, acc + weight) of
            SOME interval => SOME interval
          | NONE => largestInterval (index, left, acc)

  fun prevMatch (index, rope) = 
    case rope of
      SOME rope => helpPrevMatch (index, rope, 0)
    | NONE => NONE

  fun delete (index, length, rope) =
    case rope of
      SOME rope =>
        let
          val endIdx = index + length
        in
          (* get next match and split rope into two halves, if possible *)
          case nextMatch (endIdx, rope) of
            SOME {startIdx = nextMatchStartIdx, ...} =>
              let
                val left = splitKeepingStart (index, rope)
                val right = splitKeepingEnd (endIdx, rope)
                val newRightStartIdx = nextMatchStartIdx - length
              in
                case (left, right) of
                  (SOME left, SOME right) =>
                    (* can split into two halves *)
                    let
                      (* calculate absolute index of interval at start of right rope *)
                      val leftEndIdx = uLargestIdx (left, 0)
                      val rightStartIdx = smallestIdx right + leftEndIdx

                      (* calculate length to decremens by *)
                      val decrementBy = rightStartIdx - newRightStartIdx
                    in
                      (* decrement right, and then concatenate it with left *)
                      SOME (concatenate (
                        left, 
                        decrement (decrementBy, right)
                      ))
                    end
                | (SOME left, NONE) => 
                    (* return left, because there is no interval in right, ss nothing to decrement *)
                    SOME left
                | (NONE, SOME right) =>
                    let
                      (* calculate how much to decrement by, and then decrement without joining, because there are no intetvals to join with in left *)
                      val rightStartIdx = smallestIdx right
                      val decrementBy = rightStartIdx - newRightStartIdx
                    in
                      SOME (decrement (decrementBy, right))
                    end
                | (NONE, NONE) => 
                    (* no valid intervals in left or right, so return NONE *)
                    NONE
              end
          | NONE => 
              (* no matches to decremens after endIdx, so just split left *)
              splitKeepingStart (index, rope)
        end
    | NONE => 
        (* rope is empty, so there are no intervals to delete, so return NONE *)
        NONE

  fun insert (intervalStartIndex, intervalEndIndex, rope) =
    case rope of
      SOME rope =>
        let
          val left = splitKeepingStart (intervalStartIndex, rope)
          val right = splitKeepingEnd (intervalEndIndex, rope)
        in
          case (left, right) of
            (SOME left, SOME right) =>
              (* can split into two halves *)
              let
                val leftEndIdx = uLargestIdx (left, 0)
                val decrementBy = intervalEndIndex - leftEndIdx
  
                (* decrement new interval by leftEndIdx so that its relative index inside the rope is the same as the absoute index passed in as an argument *)
                val newInterval = 
                  Leaf {startIdx = intervalStartIndex - leftEndIdx, endIdx = intervalEndIndex - leftEndIdx}
  
                val newLeft = concatenate (left, newInterval)
                val newRight = decrement (decrementBy, right)
              in
                SOME (concatenate (newLeft, newRight))
              end
          | (SOME left, NONE) =>
              (* can't split right, so just concatenate to left *)
              let
                val leftEndIdx = uLargestIdx (left, 0)
                val newInterval = 
                  Leaf {startIdx = intervalStartIndex - leftEndIdx, endIdx = intervalEndIndex - leftEndIdx}
              in
                SOME (concatenate (left, newInterval))
              end
          | (NONE, SOME right) =>
              (* decrement right by end of new interval, and then concatenate *)
              let
                val newInterval = 
                  Leaf {startIdx = intervalStartIndex, endIdx = intervalEndIndex}
                val newRight = decrement (intervalEndIndex, right)
              in
                SOME (concatenate (newInterval, newRight))
              end
          | (NONE, NONE) =>
              (* no intervals remain after splitting, so just return new interval *)
              let
                val newInterval = 
                  Leaf {startIdx = intervalStartIndex, endIdx = intervalEndIndex}
              in
                SOME newInterval
              end
        end
    | NONE =>
        let
          val newInterval = 
            Leaf {startIdx = intervalStartIndex, endIdx = intervalEndIndex}
        in
          SOME newInterval
        end

  fun helpToList (rope, listAcc, weightAcc) =
    case rope of
      Leaf {startIdx, endIdx} =>
        {startIdx = startIdx + weightAcc, endIdx = endIdx + weightAcc} :: listAcc
    | Concat (left, weight, right) =>
        let
          val listAcc = helpToList (right, listAcc, weightAcc + weight)
        in
          helpToList (left, listAcc, weightAcc)
        end

  fun toList rope =
    case rope of
      SOME rope => helpToList (rope, [], 0)
    | NONE => []
end

(* insertion tests *)
val r1 = IntervalRope.insert (7, 9, NONE)
val r1Pass = 
  IntervalRope.toList r1 = [{startIdx = 7, endIdx = 9}]

val r2 = IntervalRope.insert (1, 1, r1)
val r2Pass = 
  IntervalRope.toList r2 = [{startIdx = 1, endIdx = 1}, {startIdx = 7, endIdx = 9}]

val r3 = IntervalRope.insert (3, 5, r2)
val r3Pass =
  IntervalRope.toList r3 = [{startIdx = 1, endIdx = 1}, {startIdx = 3, endIdx = 5}, {startIdx = 7, endIdx = 9}]

val r4 = IntervalRope.insert (13, 15, r3)
val r4Pass = 
  IntervalRope.toList r4 = [{startIdx = 1, endIdx = 1}, {startIdx = 3, endIdx = 5}, {startIdx = 7, endIdx = 9}, {startIdx = 13, endIdx = 15}]

(* deletion tests *)
(* decrements last interval from 13-15 by 1, changing it to 12-14 *)
val r5 = IntervalRope.delete (11, 1, r4)
val r5Pass =  
  IntervalRope.toList r5 = [{startIdx = 1, endIdx = 1}, {startIdx = 3, endIdx = 5}, {startIdx = 7, endIdx = 9}, {startIdx = 12, endIdx = 14}]

(* deletes last interval *)
val r6 = IntervalRope.delete (11, 5, r4)
val r6Pass =
  IntervalRope.toList r6 = [{startIdx = 1, endIdx = 1}, {startIdx = 3, endIdx = 5}, {startIdx = 7, endIdx = 9}]

(* deletes first interval and decrements subsequent ones *) 
val r7 = IntervalRope.delete (1, 1, r4)
val r7Pass =
  IntervalRope.toList r7 = [{startIdx = 2, endIdx = 4}, {startIdx = 6, endIdx =
  8}, {startIdx = 12, endIdx = 14}]

(* deletes middle interval and decrements subsequent ones *) 
val r8 = IntervalRope.delete (3, 2, r4)
val r8Pass =
  IntervalRope.toList r8 = [{startIdx = 1, endIdx = 1}, {startIdx = 5, endIdx = 7}, {startIdx = 11, endIdx = 13}]
