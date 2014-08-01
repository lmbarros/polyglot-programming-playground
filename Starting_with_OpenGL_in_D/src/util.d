/**
 * Assorted utilities for my SDL/OpenGL experiments.
 *
 * Author: Leandro Motta Barros
 */

module util;

/**
 * Boilerplate code for reference-counted reference objects.
 *
 * By "reference objects", I mean things that are represented by some kind of
 * reference, like OpenGL names and SDL pointers-to-objects.
 *
 * This shall be mixed into a $(D struct) wrapping the object. Two requirements
 * are put into this $(D struct):
 *
 * $(OL
 *
 *    $(LI The $(D initRefCount()) method must be called upon initialization.)
 *
 *    $(LI The $(D freeResources()) method must be implemented; this will be
 *    called by the boilerplate code when the last reference to the object is
 *    gone.)
 * )
 */
mixin template RefCountedBoilerplate()
{
   /// Pointer to the reference count.
   private int* refCount;

   /// Allocates memory for the reference counter, sets it to one.
   private void initRefCount()
   {
      refCount = cast(int*)malloc(typeof(*refCount).sizeof);
      *refCount = 1;
   }

   /// Is this object's reference counter initialized?
   private @property bool isRefCountInited()
   {
      return refCount !is null;
   }

   /**
    * Decrements the reference counter; if it reaches zero, frees the reference
    * counter memory and calls $(D freeResources()).
    */
   public ~this()
   {
      if (!isRefCountInited)
         return;

      --(*refCount);

      if (*refCount == 0)
      {
         freeResources();
         free(refCount);
      }
   }

   /// Increments the reference counter.
   public this(this)
   in
   {
      assert(isRefCountInited,
             "Cannot copy uninitialized reference-counted objects");
   }
   body
   {
      ++(*refCount);
   }
}
